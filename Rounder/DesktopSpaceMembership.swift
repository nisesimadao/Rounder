import AppKit

/// Assigns each strip to exactly one ordinary Space. Separate strips let
/// WindowServer draw both desktops during an interactive swipe.
final class DesktopSpaceMembership {
    private typealias Main = @convention(c) () -> Int32
    private typealias Copy = @convention(c) (Int32) -> Unmanaged<CFArray>?
    private typealias Move = @convention(c) (Int32, UInt64, CFArray, Int32) -> Void
    private typealias CopyWindows = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?
    private static let functions: (main: Main, copy: Copy, move: Move, copyWindows: CopyWindows)? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let main = dlsym(handle, "SLSMainConnectionID"),
              let copy = dlsym(handle, "SLSCopyManagedDisplaySpaces"),
              let move = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces"),
              let copyWindows = dlsym(handle, "SLSCopySpacesForWindows") else { return nil }
        return (unsafeBitCast(main, to: Main.self), unsafeBitCast(copy, to: Copy.self),
                unsafeBitCast(move, to: Move.self),
                unsafeBitCast(copyWindows, to: CopyWindows.self))
    }()

    private var appliedIDs: [UInt64] = []

    /// Pure parser shared with tests; fullscreen and tiled child Spaces are excluded.
    static func ordinarySpaceIDs(in displays: [[String: Any]], identifier: String, isPrimary: Bool) -> [UInt64] {
        guard let display = displays.first(where: {
            let value = $0["Display Identifier"] as? String
            return value == identifier || (isPrimary && value == "Main")
        }), let spaces = display["Spaces"] as? [[String: Any]] else { return [] }
        return Array(Set(spaces.compactMap { space in
            guard space["type"] as? Int == 0 else { return nil }
            return (space["ManagedSpaceID"] as? NSNumber)?.uint64Value
        })).sorted()
    }

    func invalidate() { appliedIDs = [] }

    static func spaceIDs(for displayID: CGDirectDisplayID) -> [UInt64]? {
        guard let functions,
              let displays = functions.copy(functions.main())?.takeRetainedValue() as? [[String: Any]],
              let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else { return nil }
        return ordinarySpaceIDs(in: displays, identifier: CFUUIDCreateString(nil, uuid) as String,
                                isPrimary: displayID == CGMainDisplayID())
    }

    @discardableResult
    func attach(_ window: NSWindow, spaceID: UInt64) -> Bool {
        guard let functions = Self.functions, window.windowNumber > 0 else { return false }
        let windows = [NSNumber(value: window.windowNumber)] as CFArray
        // AppKit can reassociate a window after it is ordered. Check its actual
        // membership even when the requested destination has not changed.
        let actual = functions.copyWindows(functions.main(), 7, windows)?.takeRetainedValue() as? [NSNumber]
        if appliedIDs == [spaceID], actual?.map(\.uint64Value) == [spaceID] { return true }
        functions.move(functions.main(), spaceID, windows, 0x7)
        guard let updated = functions.copyWindows(functions.main(), 7, windows)?.takeRetainedValue() as? [NSNumber],
              updated.map(\.uint64Value) == [spaceID] else { return false }
        appliedIDs = [spaceID]
        return true
    }
}
