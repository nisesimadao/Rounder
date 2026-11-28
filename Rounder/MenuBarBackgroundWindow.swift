import AppKit

/// A click-through strip behind the system menu text/status items.
/// Approach adapted from mllle/macbook-notchless (MIT); see THIRD_PARTY_NOTICES.
final class MenuBarBackgroundWindow: NSWindow {
    let overlayDisplayID: CGDirectDisplayID
    let desktopSpaceID: UInt64?
    private var backgroundAppearance = MenuBarBackgroundAppearance()
    private var gamingEnabled = false
    private var gamingSpeed = 1.0
    private var gamingCornerSize: CGFloat = 0
    private let desktopMembership = DesktopSpaceMembership()
    private var lastMenuBarFrame: NSRect?
    private(set) var usesDesktopSpaceMembership = false

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(screen: NSScreen, displayID: CGDirectDisplayID, isFullScreen: Bool = false, desktopSpaceID: UInt64? = nil) {
        overlayDisplayID = displayID
        self.desktopSpaceID = desktopSpaceID ?? DesktopSpaceMembership.spaceIDs(for: displayID)?.first
        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        isExcludedFromWindowsMenu = true
        // The Mission Control coordinator hides this strip and the screen-pinned
        // top corners together. Transient would hide the strip ahead of corners.
        collectionBehavior = [.stationary, .ignoresCycle]
        // The main menu itself is level 24 on supported macOS versions.
        // statusBar - 1 is also 24, so ordering a new strip front can cover
        // application menu labels. Stay strictly below both system levels.
        level = NSWindow.Level(rawValue: Int(min(CGWindowLevelForKey(.mainMenuWindow),
                                             CGWindowLevelForKey(.statusWindow))) - 1)
        contentView = MenuBarBackgroundView(frame: .zero)
        updatePlacement(on: screen, isFullScreen: isFullScreen)
    }

    func setCornerColor(_ color: NSColor) {
        backgroundAppearance.cornerColor = color
        backgroundColor = backgroundAppearance.backgroundColor
        isOpaque = backgroundAppearance.isOpaque
    }

    func setGamingMode(_ enabled: Bool, speed: Double, cornerSize: CGFloat) {
        gamingEnabled = enabled
        backgroundAppearance.gaming = enabled
        isOpaque = backgroundAppearance.isOpaque
        gamingSpeed = speed
        gamingCornerSize = cornerSize
        (contentView as? MenuBarBackgroundView)?.setGamingMode(enabled, speed: speed, cornerSize: cornerSize)
    }

    func updateCornerSize(_ cornerSize: CGFloat) {
        gamingCornerSize = cornerSize
        (contentView as? MenuBarBackgroundView)?.updateCornerSize(cornerSize)
    }

    func sibling(on screen: NSScreen, spaceID: UInt64, isFullScreen: Bool) -> MenuBarBackgroundWindow {
        let window = MenuBarBackgroundWindow(screen: screen, displayID: overlayDisplayID,
                                             isFullScreen: isFullScreen, desktopSpaceID: spaceID)
        window.lastMenuBarFrame = lastMenuBarFrame
        window.alphaValue = alphaValue
        window.setCornerColor(backgroundAppearance.cornerColor)
        window.setGamingMode(gamingEnabled, speed: gamingSpeed, cornerSize: gamingCornerSize)
        window.updatePlacement(on: screen, isFullScreen: isFullScreen)
        return window
    }

    func prepareForClose() {
        setGamingMode(false, speed: 1, cornerSize: 0)
    }

    func updatePlacement(on screen: NSScreen, isFullScreen: Bool = false) {
        let measuredFrame = CornerGeometry.menuBarFrame(screenFrame: screen.frame, visibleFrame: screen.visibleFrame)
        if !isFullScreen { lastMenuBarFrame = measuredFrame }
        // visibleFrame may lose its top inset in fullscreen. Preserve the frame
        // used by the ordinary Spaces that are still sliding out of view.
        let barFrame = isFullScreen ? (lastMenuBarFrame ?? measuredFrame ?? NSRect(
            x: screen.frame.minX, y: screen.frame.maxY - NSStatusBar.system.thickness,
            width: screen.frame.width, height: NSStatusBar.system.thickness)) : measuredFrame
        guard let barFrame else {
            if isVisible { orderOut(nil) }
            desktopMembership.invalidate()
            return
        }
        if frame != barFrame { setFrame(barFrame, display: false) }
        if !isVisible {
            orderFrontRegardless()
            desktopMembership.invalidate()
        }
        if collectionBehavior.contains(.canJoinAllSpaces) {
            collectionBehavior = [.stationary, .ignoresCycle]
            desktopMembership.invalidate()
        }
        usesDesktopSpaceMembership = desktopSpaceID.map { desktopMembership.attach(self, spaceID: $0) } ?? false
        if !usesDesktopSpaceMembership {
            // Older systems without these optional APIs keep the previous
            // visibility behavior, rather than painting over fullscreen apps.
            collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            if isFullScreen { orderOut(nil) }
        }
    }
}
