import AppKit
import QuartzCore

/// One display-synchronized clock for color scrubbing and fullscreen tracking.
/// Manual clocks let tests exercise the same code without touching a display.
@MainActor
final class OverlayFrameClock: NSObject {
    static let shared = OverlayFrameClock()
    private let automaticallyStart: Bool
    private var displayLink: CADisplayLink?
    private var handlers: [UUID: (CFTimeInterval) -> Void] = [:]
    private var lastTimestamp: CFTimeInterval?
    var observerCount: Int { handlers.count }

    init(automaticallyStart: Bool = true) {
        self.automaticallyStart = automaticallyStart
        super.init()
    }

    func add(_ handler: @escaping (CFTimeInterval) -> Void) -> UUID {
        let id = UUID()
        handlers[id] = handler
        if automaticallyStart && displayLink == nil {
            if let screen = NSScreen.screens.max(by: { $0.maximumFramesPerSecond < $1.maximumFramesPerSecond }) {
                let link = screen.displayLink(target: self, selector: #selector(displayFrame(_:)))
                let rate = Float(max(1, screen.maximumFramesPerSecond))
                link.preferredFrameRateRange = CAFrameRateRange(minimum: rate, maximum: rate, preferred: rate)
                link.add(to: .main, forMode: .common)
                displayLink = link
            }
        }
        return id
    }

    func remove(_ id: UUID) {
        handlers.removeValue(forKey: id)
        if handlers.isEmpty {
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = nil
        }
    }

    func advance(to timestamp: CFTimeInterval) {
        guard timestamp.isFinite, lastTimestamp.map({ timestamp >= $0 }) ?? true else { return }
        lastTimestamp = timestamp
        for handler in Array(handlers.values) { handler(timestamp) }
    }

    @objc private func displayFrame(_ link: CADisplayLink) {
        advance(to: link.targetTimestamp > 0 ? link.targetTimestamp : CACurrentMediaTime())
    }
}
