import AppKit

enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }
@main struct FullscreenMenuCornersTests {
    static func main() {
        let bounds: [CGDirectDisplayID: CGRect] = [1: CGRect(x: 0, y: 0, width: 1680, height: 1050),
                                                  2: CGRect(x: -1920, y: -100, width: 1920, height: 1080)]
        func menu(_ frame: CGRect, level: Int = 24, alpha: Double = 1) -> [String: Any] {
            [kCGWindowLayer as String: level, kCGWindowBounds as String: frame.dictionaryRepresentation,
             kCGWindowAlpha as String: alpha]
        }
        let shown = menu(CGRect(x: 0, y: 0, width: 1680, height: 30))
        precondition(FullscreenMenuCorners.visibleInsets(windows: [shown], screens: bounds) == [1: 30])
        precondition(FullscreenMenuCorners.visibleInsets(windows: [menu(CGRect(x: 0, y: -15, width: 1680, height: 30))], screens: bounds) == [1: 15])
        precondition(FullscreenMenuCorners.visibleInsets(windows: [menu(CGRect(x: 0, y: -30, width: 1680, height: 30))], screens: bounds).isEmpty)
        precondition(FullscreenMenuCorners.visibleInsets(windows: [menu(CGRect(x: -1920, y: -100, width: 1920, height: 24))], screens: bounds) == [2: 24])
        precondition(FullscreenMenuCorners.visibleInsets(windows: [menu(CGRect(x: 0, y: 0, width: 1680, height: 1050)),
            menu(CGRect(x: 0, y: 0, width: 200, height: 30)), menu(CGRect(x: 0, y: 0, width: 1680, height: 30), level: 23),
            menu(CGRect(x: 0, y: 0, width: 1680, height: 30), alpha: 0)], screens: bounds).isEmpty)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let screen = NSScreen.screens[0], id = screen.displayID!
        let manager = FullscreenMenuCorners()
        manager.configure(.init(radius: 20, style: .rounded, color: .black, gaming: false, speed: 1,
                                topLeft: true, topRight: true, displayIDs: [id]), fullscreen: [])
        let liveMenu = menu(CGRect(x: screen.frame.minX, y: 0, width: screen.frame.width, height: 30))
        manager.observe([liveMenu], screens: [screen])
        precondition(manager.overlayWindows.isEmpty, "Ordinary desktops must not get fullscreen-hover corners")
        manager.setFullscreenDisplays([id])
        manager.observe([liveMenu], screens: [screen])
        precondition(manager.overlayWindows.count == 2)
        precondition(manager.overlayWindows.allSatisfy { $0.alphaValue == 1 && $0.frame.maxY == screen.frame.maxY - 30 })
        let numbers = Set(manager.overlayWindows.map(\.windowNumber))
        manager.observe([], screens: [screen])
        precondition(manager.overlayWindows.allSatisfy { $0.alphaValue == 0 })
        manager.observe([liveMenu], screens: [screen])
        precondition(Set(manager.overlayWindows.map(\.windowNumber)) == numbers)
        manager.setMissionControlDisplays([id])
        precondition(manager.overlayWindows.allSatisfy { $0.alphaValue == 0 })
        manager.observe([liveMenu], screens: [screen])
        precondition(manager.overlayWindows.allSatisfy { $0.alphaValue == 0 })
        manager.setMissionControlDisplays([])
        manager.setFullscreenDisplays([])
        manager.observe([liveMenu], screens: [screen])
        precondition(manager.overlayWindows.allSatisfy { $0.alphaValue == 0 })
        manager.close()
        print("PASS: revealed fullscreen menus get top corners below their visible edge; hiding, ordinary desktops and Mission Control suppress them")
    }
}
