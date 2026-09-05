//
//  MenuBarController.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import SwiftUI

// MARK: - Constants
struct MenuBarControllerConstants {
    static let iconSize = NSSize(width: 16, height: 16)
}

/// AppKit owns only the real status item / NSMenu tracking session.
/// The panel contents remain SwiftUI so the controls can share @AppStorage with
/// the existing Settings window without introducing a second settings model.
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?
    private var menu: NSMenu?

    func setupMenuBar(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate

        // setupMenuBar is normally called once, but keeping it idempotent avoids
        // duplicate status items if the launch flow is ever re-entered.
        guard statusItem == nil else { return }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            if let icon = NSImage(named: "StatusIcon") {
                icon.size = MenuBarControllerConstants.iconSize
                icon.isTemplate = true
                button.image = icon
            }
            button.toolTip = String(localized: "rounder_tooltip")
        }

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
            onOpenSettings: { [weak self] in
                self?.openSettingsFromPanel()
            },
            onQuit: { [weak self] in
                self?.quitFromPanel()
            }
        )

        let hostingView = MenuBarPanelHostingView(rootView: panelView)
        hostingView.frame.size = hostingView.fittingSize

        let panelItem = NSMenuItem()
        panelItem.view = hostingView

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(panelItem)
        statusItem.menu = menu
        self.menu = menu
    }

    /// A window cannot reliably become key while an NSMenu tracking session is
    /// still active. Ask AppKit to end tracking, then open Settings on the next
    /// main-loop turn rather than synchronously from the SwiftUI button action.
    private func openSettingsFromPanel() {
        menu?.cancelTracking()
        DispatchQueue.main.async { [weak self] in
            self?.appDelegate?.showSettings()
        }
    }

    private func quitFromPanel() {
        menu?.cancelTracking()
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
}

/// NSMenuItem custom views are frame-based rather than constrained by an Auto
/// Layout parent. Keep the AppKit frame synchronized with SwiftUI's ideal size.
private final class MenuBarPanelHostingView: NSHostingView<MenuBarPanelView> {
    required init(rootView: MenuBarPanelView) {
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder: NSCoder) {
        fatalError("MenuBarPanelHostingView does not support NSCoder")
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        let targetSize = fittingSize
        if frame.size != targetSize {
            setFrameSize(targetSize)
        }
    }
}
