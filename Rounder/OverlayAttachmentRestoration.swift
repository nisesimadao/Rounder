import AppKit

@MainActor
protocol OverlayAttachmentWindow: AnyObject {
    var collectionBehavior: NSWindow.CollectionBehavior { get set }
    var level: NSWindow.Level { get set }
}
extension NSWindow: OverlayAttachmentWindow {}

@MainActor
enum OverlayAttachmentRestoration {
    static func restore(_ window: OverlayAttachmentWindow, behavior: NSWindow.CollectionBehavior,
                        level: NSWindow.Level, move: () -> Bool) -> Bool {
        let pinnedBehavior = window.collectionBehavior
        // Both fullscreen and desktop modes already have canJoinAllSpaces set.
        // Force a real false -> true transition after the private move, otherwise
        // AppKit can leave the glow attached only to the one destination Space.
        window.collectionBehavior = pinnedBehavior.subtracting(.canJoinAllSpaces)
        guard move() else {
            window.collectionBehavior = pinnedBehavior
            return false
        }
        window.level = level
        window.collectionBehavior = behavior
        return true
    }
}
