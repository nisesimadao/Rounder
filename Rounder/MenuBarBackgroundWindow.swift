import AppKit

/// A click-through black strip behind the system menu text/status items.
/// Approach adapted from mllle/macbook-notchless (MIT); see THIRD_PARTY_NOTICES.
final class MenuBarBackgroundWindow: NSWindow {
    let overlayDisplayID: CGDirectDisplayID

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(screen: NSScreen, displayID: CGDirectDisplayID, isFullScreen: Bool = false) {
        overlayDisplayID = displayID
        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        isExcludedFromWindowsMenu = true
        // The Mission Control coordinator hides this strip and the screen-pinned
        // top corners together. Transient would hide the strip ahead of corners.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue - 1)
        contentView = MenuBarBackgroundView(frame: .zero)
        updatePlacement(on: screen, isFullScreen: isFullScreen)
    }

    func setGamingMode(_ enabled: Bool, speed: Double, cornerSize: CGFloat) {
        collectionBehavior = enabled
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
            : [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        (contentView as? MenuBarBackgroundView)?.setGamingMode(enabled, speed: speed, cornerSize: cornerSize)
    }

    func updateCornerSize(_ cornerSize: CGFloat) {
        (contentView as? MenuBarBackgroundView)?.updateCornerSize(cornerSize)
    }

    func prepareForClose() {
        setGamingMode(false, speed: 1, cornerSize: 0)
    }

    func updatePlacement(on screen: NSScreen, isFullScreen: Bool = false) {
        guard !isFullScreen, let barFrame = CornerGeometry.menuBarFrame(
            screenFrame: screen.frame, visibleFrame: screen.visibleFrame
        ) else {
            if isVisible { orderOut(nil) }
            return
        }
        if frame != barFrame { setFrame(barFrame, display: false) }
        if !isVisible { orderFrontRegardless() }
    }
}
