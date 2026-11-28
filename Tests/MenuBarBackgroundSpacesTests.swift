import AppKit

// Compile with MenuBarBackgroundSpaces, DesktopSpaceMembership, menu-background,
// corner/glow sources, and NSScreen+DisplayInfo in a logged-in UI session.
enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }
@main struct MenuBarBackgroundSpacesTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let screen = NSScreen.screens[0], displayID = screen.displayID!
        let ids = DesktopSpaceMembership.spaceIDs(for: displayID)!
        precondition(!ids.isEmpty)
        let first = MenuBarBackgroundWindow(screen: screen, displayID: displayID, desktopSpaceID: ids[0])
        first.setCornerColor(.blue)
        first.setGamingMode(true, speed: 2, cornerSize: 40)
        var windows = MenuBarBackgroundSpaces.reconcile([first], screens: [screen], fullScreenDisplays: [])
        precondition(windows.count == ids.count)
        precondition(Set(windows.map(\.windowNumber)).count == ids.count)
        precondition(Set(windows.compactMap(\.desktopSpaceID)) == Set(ids))
        typealias Main = @convention(c) () -> Int32
        typealias Copy = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?
        let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)!
        let connection = unsafeBitCast(dlsym(handle, "SLSMainConnectionID"), to: Main.self)()
        let copy = unsafeBitCast(dlsym(handle, "SLSCopySpacesForWindows"), to: Copy.self)
        for window in windows {
            precondition(window.backgroundColor.isEqual(NSColor.blue))
            let actual = copy(connection, 7, [NSNumber(value: window.windowNumber)] as CFArray)!.takeRetainedValue() as! [NSNumber]
            precondition(actual.map(\.uint64Value) == [window.desktopSpaceID!])
            let gradient = window.contentView!.layer!.sublayers!.compactMap { $0 as? CAGradientLayer }.first!
            precondition(gradient.animation(forKey: "rainbow")!.duration == 1.5)
            let frame = window.frame, number = window.windowNumber
            window.updatePlacement(on: screen, isFullScreen: true)
            precondition(window.isVisible && window.frame == frame && window.windowNumber == number)
        }
        let numbers = windows.map(\.windowNumber)
        windows = MenuBarBackgroundSpaces.reconcile(windows, screens: [screen], fullScreenDisplays: [displayID])
        precondition(windows.map(\.windowNumber) == numbers, "Space changes must preserve each desktop's window")
        let duplicate = first.sibling(on: screen, spaceID: ids[0], isFullScreen: false)
        windows = MenuBarBackgroundSpaces.reconcile(windows + [duplicate], screens: [screen], fullScreenDisplays: [])
        precondition(windows.map(\.windowNumber) == numbers && !duplicate.isVisible)
        for window in windows { window.prepareForClose(); window.close() }
        print("PASS: each ordinary Space has its own synchronized strip; identities survive fullscreen; duplicate windows are removed")
    }
}
