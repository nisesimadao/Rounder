import AppKit

// Compile with Rounder/DesktopSpaceMembership.swift in a logged-in UI session.
@main struct DesktopSpaceMembershipTests {
    static func main() {
        let fixtures: [[String: Any]] = [
            ["Display Identifier": "A", "Spaces": [
                ["ManagedSpaceID": 3, "type": 0], ["ManagedSpaceID": 4, "type": 4],
                ["ManagedSpaceID": 5, "type": 0], ["ManagedSpaceID": 6, "type": 5]]],
            ["Display Identifier": "B", "Spaces": [["ManagedSpaceID": 9, "type": 0]]]
        ]
        precondition(DesktopSpaceMembership.ordinarySpaceIDs(in: fixtures, identifier: "A", isPrimary: true) == [3, 5])
        precondition(DesktopSpaceMembership.ordinarySpaceIDs(in: fixtures, identifier: "B", isPrimary: false) == [9])
        precondition(DesktopSpaceMembership.ordinarySpaceIDs(in: fixtures, identifier: "C", isPrimary: false).isEmpty)
        let main: [[String: Any]] = [["Display Identifier": "Main", "Spaces": [["ManagedSpaceID": 1, "type": 0]]]]
        precondition(DesktopSpaceMembership.ordinarySpaceIDs(in: main, identifier: "A", isPrimary: true) == [1])
        precondition(DesktopSpaceMembership.ordinarySpaceIDs(in: main, identifier: "A", isPrimary: false).isEmpty)

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let ids = DesktopSpaceMembership.spaceIDs(for: CGMainDisplayID())!
        precondition(!ids.isEmpty)
        var windows: [NSWindow] = []
        for id in ids {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.stationary, .ignoresCycle]
            window.orderFrontRegardless()
            let membership = DesktopSpaceMembership()
            precondition(membership.attach(window, spaceID: id))
            for _ in 0..<10 { precondition(membership.attach(window, spaceID: id)) }
            windows.append(window)
        }
        typealias Main = @convention(c) () -> Int32
        typealias CopyWindows = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?
        let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)!
        let connection = unsafeBitCast(dlsym(handle, "SLSMainConnectionID"), to: Main.self)()
        let copyWindows = unsafeBitCast(dlsym(handle, "SLSCopySpacesForWindows"), to: CopyWindows.self)
        for (window, id) in zip(windows, ids) {
            let values = copyWindows(connection, 7, [NSNumber(value: window.windowNumber)] as CFArray)!.takeRetainedValue() as! [NSNumber]
            precondition(values.map(\.uint64Value) == [id], "Each desktop must have its own strip, with no shared membership")
            window.close()
        }
        print("PASS: independent strips belong to individual ordinary Spaces:", ids)
    }
}
