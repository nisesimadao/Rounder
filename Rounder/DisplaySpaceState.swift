import AppKit

/// Reads per-display Space types through the same optional SkyLight framework
/// used for screen-pinned overlays. A native fullscreen Space has type 4.
enum DisplaySpaceState {
    private typealias MainConnection = @convention(c) () -> Int32
    private typealias CopyDisplaySpaces = @convention(c) (Int32) -> Unmanaged<CFArray>?
    private static let functions: (MainConnection, CopyDisplaySpaces)? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let main = dlsym(handle, "SLSMainConnectionID"),
              let copy = dlsym(handle, "SLSCopyManagedDisplaySpaces") else { return nil }
        return (unsafeBitCast(main, to: MainConnection.self),
                unsafeBitCast(copy, to: CopyDisplaySpaces.self))
    }()

    static func fullScreenDisplayIDs() -> Set<CGDirectDisplayID> {
        let screens = NSScreen.screens
        guard let functions,
              let value = functions.1(functions.0())?.takeRetainedValue(),
              let displays = value as? [[String: Any]] else {
            // Public fallback for the active display; visibleFrame handles the
            // other displays when the optional private API is unavailable.
            if NSApp.currentSystemPresentationOptions.contains(.fullScreen),
               let id = NSScreen.main?.displayID { return [id] }
            return []
        }
        let identifiers = fullScreenIdentifiers(in: displays)
        return Set(screens.compactMap { screen in
            guard let id = screen.displayID,
                  let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
            let identifier = CFUUIDCreateString(nil, uuid) as String
            let isMain = screen === screens.first
            return identifiers.contains(identifier) || (isMain && identifiers.contains("Main")) ? id : nil
        })
    }

    static func fullScreenIdentifiers(in displays: [[String: Any]]) -> Set<String> {
        Set(displays.compactMap { display in
            guard let current = display["Current Space"] as? [String: Any],
                  current["type"] as? Int == 4,
                  let identifier = display["Display Identifier"] as? String else { return nil }
            return identifier
        })
    }
}
