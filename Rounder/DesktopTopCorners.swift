import AppKit

/// Extra desktop-owned top corners preserve the incoming desktop's menu inset
/// while the screen-pinned corners still belong to a fullscreen transition.
final class DesktopTopCorners {
    struct Configuration {
        var radius: CGFloat
        var style: CornerCutoutStyle
        var color: NSColor
        var gaming: Bool
        var speed: Double
        var topLeft: Bool
        var topRight: Bool
        var displayIDs: Set<CGDirectDisplayID>
    }
    private struct Entry {
        let displayID: CGDirectDisplayID
        let spaceID: UInt64
        let right: Bool
        let window: CornerOverlayWindow
        let membership: DesktopSpaceMembership
    }
    private var configuration: Configuration?
    private var entries: [Entry] = []
    private var normalFrames: [CGDirectDisplayID: NSRect] = [:]
    var windows: [CornerOverlayWindow] { entries.map(\.window) }

    func configure(_ configuration: Configuration?, screens: [NSScreen], fullscreen: Set<CGDirectDisplayID>) {
        close()
        self.configuration = configuration
        refresh(screens: screens, fullscreen: fullscreen)
    }

    func refresh(screens: [NSScreen], fullscreen: Set<CGDirectDisplayID>) {
        guard let configuration else { return }
        var updated: [Entry] = []
        for screen in screens {
            guard let displayID = screen.displayID, configuration.displayIDs.contains(displayID) else { continue }
            let frame: NSRect
            if !fullscreen.contains(displayID) {
                frame = CornerGeometry.overlayFrame(screenFrame: screen.frame, visibleFrame: screen.visibleFrame,
                                                    excludeMenuBar: true)
                normalFrames[displayID] = frame
            } else {
                frame = normalFrames[displayID] ?? screen.frame.withTopInset(
                    max(NSStatusBar.system.thickness, screen.safeAreaInsets.top))
            }
            guard let ids = DesktopSpaceMembership.spaceIDs(for: displayID), !ids.isEmpty else {
                updated.append(contentsOf: entries.filter { $0.displayID == displayID })
                continue
            }
            for id in ids {
                for right in [false, true] where right ? configuration.topRight : configuration.topLeft {
                    if let entry = entries.first(where: { $0.displayID == displayID && $0.spaceID == id && $0.right == right }) {
                        entry.window.updatePlacement(in: frame)
                        entry.membership.attach(entry.window, spaceID: id)
                        updated.append(entry)
                    } else {
                        let corner: ScreenCorner = right ? .topRight : .topLeft
                        let size = CornerGeometry.cornerSize(radius: configuration.radius, style: configuration.style)
                        let window = CornerOverlayWindow(corner: CornerGeometry.windowOrigin(in: frame, corner: corner, cornerSize: size),
                            size: size, radius: configuration.radius, color: configuration.color,
                            cutoutStyle: configuration.style, cornerType: corner.drawingCorner)
                        window.overlayDisplayID = displayID
                        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) - 1)
                        window.collectionBehavior = [.stationary, .ignoresCycle]
                        window.setGamingMode(configuration.gaming, speed: configuration.speed, baseHue: corner.gamingBaseHue)
                        let membership = DesktopSpaceMembership()
                        if membership.attach(window, spaceID: id) {
                            updated.append(Entry(displayID: displayID, spaceID: id, right: right, window: window, membership: membership))
                        } else {
                            window.prepareForClose()
                            window.close()
                        }
                    }
                }
            }
        }
        for entry in entries where !updated.contains(where: { $0.window === entry.window }) {
            entry.window.prepareForClose()
            entry.window.close()
        }
        entries = updated
    }

    func updateGeometry(radius: CGFloat, style: CornerCutoutStyle) {
        configuration?.radius = radius
        configuration?.style = style
        for entry in entries { entry.window.updateGeometry(radius: radius, cutoutStyle: style) }
    }

    func close() {
        for entry in entries { entry.window.prepareForClose(); entry.window.close() }
        entries = []
        normalFrames = [:]
        configuration = nil
    }
}

private extension NSRect {
    func withTopInset(_ inset: CGFloat) -> NSRect {
        NSRect(x: minX, y: minY, width: width, height: max(0, height - inset))
    }
}
