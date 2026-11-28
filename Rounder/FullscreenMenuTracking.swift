import CoreGraphics
import Foundation

/// High-rate samples only while a fullscreen menu can be changing. Discovery
/// stays cheap when the pointer is away from the top and no menu is visible.
@MainActor
final class FullscreenMenuTracking {
    private let clock: OverlayFrameClock
    private let snapshot: () -> [[String: Any]]?
    private var observer: UUID?
    var shouldSample: () -> Bool = { false }
    var onSnapshot: ([[String: Any]]) -> Void = { _ in }

    init(clock: OverlayFrameClock? = nil, snapshot: @escaping () -> [[String: Any]]? = {
        CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
    }) {
        self.clock = clock ?? .shared
        self.snapshot = snapshot
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard observer == nil else { return }
            observer = clock.add { [weak self] _ in
                guard let self, self.shouldSample(), let windows = self.snapshot() else { return }
                self.onSnapshot(windows)
            }
        } else if let observer {
            clock.remove(observer)
            self.observer = nil
        }
    }
}
