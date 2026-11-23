import Cocoa
import SwiftUI

struct MenuBarControllerConstants {
    static let iconSize = NSSize(width: 16, height: 16)
}

/// The status button owns the open/closed state; the nonactivating panel can
/// become key without activating Rounder or starting an NSMenu tracking loop.
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?
    private var panel: MenuBarPanel?
    private var eventMonitors: [Any] = []
    private var isObservingDefaults = false
    private var handledHiddenLaunchRecovery = false

    deinit {
        NotificationCenter.default.removeObserver(self)
        eventMonitors.forEach(NSEvent.removeMonitor)
    }

    func setupMenuBar(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        if !isObservingDefaults {
            NotificationCenter.default.addObserver(
                self, selector: #selector(userDefaultsDidChange),
                name: UserDefaults.didChangeNotification, object: UserDefaults.standard
            )
            isObservingDefaults = true
        }
        applyMenuBarVisibility()
        if !handledHiddenLaunchRecovery,
           !MenuBarVisibilityPreference.isVisible,
           !MenuBarVisibilityPreference.wasLaunchedAsLoginItem {
            handledHiddenLaunchRecovery = true
            DispatchQueue.main.async { [weak self] in self?.appDelegate?.showSettings() }
        }
    }

    @objc private func userDefaultsDidChange(_ notification: Notification) {
        // Defaults notifications may arrive from a background thread or from a
        // SwiftUI binding setter. Defer AppKit work to the next main-loop turn.
        DispatchQueue.main.async { [weak self] in self?.applyMenuBarVisibility() }
    }

    private func applyMenuBarVisibility() {
        if MenuBarVisibilityPreference.isVisible {
            createMenuBarIfNeeded()
        } else if let statusItem {
            closePanel()
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    private func createMenuBarIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            if let icon = NSImage(named: "StatusIcon") {
                icon.size = MenuBarControllerConstants.iconSize
                icon.isTemplate = true
                button.image = icon
            }
            // Keep the selected background after the mouse-up action returns.
            (button.cell as? NSButtonCell)?.showsStateBy = [.changeBackgroundCellMask]
            button.toolTip = String(localized: "rounder_tooltip")
            button.target = self
            button.action = #selector(togglePanel)
            button.sendAction(on: .leftMouseUp)
        }
    }

    @objc private func togglePanel() {
        if panel?.isVisible == true {
            closePanel()
        } else {
            // A system-hidden panel is not an open menu. Clear stale state so
            // the next click opens immediately instead of merely resetting it.
            closePanel()
            showPanel()
        }
    }

    private func showPanel() {
        guard NSApp.modalWindow == nil, let button = statusItem?.button,
              let statusWindow = button.window else { return }
        let panelView = MenuBarPanelView(
            onEnabledChanged: { [weak self] _ in
                // Enable changes the existence of the overlay set, so this
                // deliberately stays on the full rebuild path.
                self?.appDelegate?.recreateOverlayWindows()
            },
            onGeometryChanged: { [weak self] radius, style in
                // Radius / shape can update the existing windows in place.
                self?.appDelegate?.updateCornerGeometry(
                    radius: radius,
                    cutoutStyle: style
                )
            },
            onColorChanged: { [weak self] _ in
                // Color is changed infrequently from three quick swatches. A
                // rebuild keeps this path simple and preserves all existing
                // gaming/non-gaming color semantics.
                self?.appDelegate?.recreateOverlayWindows()
            },
            onOverlayStructureChanged: { [weak self] in
                // Corner enablement and Gaming mode change which windows exist.
                self?.appDelegate?.recreateOverlayWindows()
            },
            onOpenSettings: { [weak self] in
                self?.openSettingsFromPanel()
            },
            onQuit: { [weak self] in
                self?.quitFromPanel()
            }
        )

        let hosting = NSHostingView(rootView: MenuBarPanelRoot(content: panelView))
        hosting.layoutSubtreeIfNeeded()
        let buttonRect = statusWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = statusWindow.screen ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        let measured = hosting.fittingSize.height
        let height = min(measured.isFinite && measured > 0 ? ceil(measured) : 480,
                         visibleFrame.height)
        let size = NSSize(width: 300, height: height)
        let origin = NSPoint(
            x: min(max(buttonRect.midX - size.width / 2, visibleFrame.minX),
                   visibleFrame.maxX - size.width),
            y: max(visibleFrame.minY, buttonRect.minY - size.height)
        )
        let panel = MenuBarPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        hosting.setFrameSize(size)
        panel.contentView = hosting
        self.panel = panel
        panel.orderFrontRegardless()
        panel.makeKey()
        // A custom panel does not track the status button automatically.
        button.state = .on
        button.highlight(true)
        // The status button's mouse-up tracking clears its pressed highlight
        // after invoking our action. Reapply it once tracking has finished.
        DispatchQueue.main.async { [weak self, weak panel] in
            guard let self, let panel, self.panel === panel else { return }
            self.statusItem?.button?.highlight(true)
        }
        installEventMonitors(for: panel)
    }

    private func closePanel() {
        let closingPanel = panel
        panel = nil
        eventMonitors.forEach(NSEvent.removeMonitor)
        eventMonitors.removeAll()
        statusItem?.button?.state = .off
        statusItem?.button?.highlight(false)
        closingPanel?.orderOut(nil)
        closingPanel?.close()
    }

    // Nonactivating panels can lose key status while the status button finishes
    // tracking its click. This is not a dismissal; outside-click monitoring,
    // Escape and the status button are the authoritative close paths.
    private func installEventMonitors(for panel: NSPanel) {
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self, weak panel] _ in
            guard let self, let panel else { return }
            let location = NSEvent.mouseLocation
            if panel.frame.contains(location) { return }
            if let button = self.statusItem?.button, let window = button.window,
               window.convertToScreen(button.convert(button.bounds, to: nil)).contains(location) {
                return
            }
            DispatchQueue.main.async { [weak self, weak panel] in
                guard let self, let panel, self.panel === panel else { return }
                self.closePanel()
            }
        }) { eventMonitors.append(monitor) }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: [clicks, .keyDown], handler: { [weak self, weak panel] event in
            guard let self, let panel, self.panel === panel else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53 {
                    self.closePanel()
                    return nil
                }
                if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
                    if event.charactersIgnoringModifiers == "," {
                        self.openSettingsFromPanel()
                        return nil
                    }
                    if event.charactersIgnoringModifiers == "q" {
                        self.quitFromPanel()
                        return nil
                    }
                }
                return event
            }
            // Leave the status button click to togglePanel; closing here would
            // immediately reopen the panel on the corresponding mouse-up.
            if event.window === self.statusItem?.button?.window { return event }
            var window = event.window
            while let current = window {
                if current === panel { return event }
                window = current.parent
            }
            DispatchQueue.main.async { [weak self, weak panel] in
                guard let self, let panel, self.panel === panel else { return }
                self.closePanel()
            }
            return event
        }) { eventMonitors.append(monitor) }
    }

    private func openSettingsFromPanel() {
        closePanel()
        DispatchQueue.main.async { [weak self] in self?.appDelegate?.showSettings() }
    }

    private func quitFromPanel() {
        closePanel()
        DispatchQueue.main.async { NSApplication.shared.terminate(nil) }
    }
}
