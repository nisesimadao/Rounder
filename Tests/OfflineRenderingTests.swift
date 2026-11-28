import AppKit
import QuartzCore

// No NSApplication.shared, windows, display links, screen queries or Space API
// mutations. Every clock and snapshot is injected; CALayers stay offscreen.
enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }

@MainActor
final class RecordingAttachment: OverlayAttachmentWindow {
    var history: [NSWindow.CollectionBehavior] = []
    var collectionBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary] {
        didSet { history.append(collectionBehavior) }
    }
    var level = NSWindow.Level(rawValue: 1000)
}

@main
struct OfflineRenderingTests {
    @MainActor static func main() {
        var failures: [String] = []
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() { failures.append(message) }
        }
        check(NSApp == nil, "Tests must not initialize an application")
        let clock = OverlayFrameClock(automaticallyStart: false)
        var appearance = MenuBarBackgroundAppearance()
        for color in [NSColor.black, .white, .red, .blue, NSColor(srgbRed: 0.2, green: 0.6, blue: 0.4, alpha: 0.5)] {
            appearance.cornerColor = color
            check(appearance.backgroundColor.isEqual(color), "Normal menu strip must use the corner color, including alpha")
            check(appearance.isOpaque == (color.alphaComponent >= 1), "Window opacity must match the selected color")
            appearance.gaming = true
            check(appearance.isOpaque, "Gaming's rainbow remains opaque")
            appearance.gaming = false
            check(appearance.backgroundColor.isEqual(color), "Leaving Gaming Mode must restore the selected corner color")
        }
        let gradient = CAGradientLayer()
        GamingGlowClock.addRainbowAnimation(to: gradient, baseHue: 0, speed: 2, menuBar: true)
        let animation = gradient.animation(forKey: "rainbow") as? CAKeyframeAnimation
        check(animation?.duration == 1.5, "Gaming speed must retain its original behavior")
        if let colors = animation?.values as? [[CGColor]] {
            for (index, frame) in colors.enumerated() {
                let expected = GamingGlowClock.gradientColors(baseHue: 0, phase: Double(index) / Double(GamingGlowClock.steps))
                    .map { GamingGlowClock.menuBarColor($0).components }
                check(frame.map(\.components) == expected, "The existing gaming palette must remain unchanged")
            }
        } else { check(false, "Gaming must retain its existing rainbow animation") }
        gradient.removeAllAnimations()
        var sampleCount = 0, deliveryCount = 0, hover = true, snapshotAvailable = true
        let tracking = FullscreenMenuTracking(clock: clock, snapshot: {
            sampleCount += 1
            return snapshotAvailable ? [] : nil
        })
        tracking.shouldSample = { hover }
        tracking.onSnapshot = { _ in deliveryCount += 1 }
        tracking.setEnabled(true)
        tracking.setEnabled(true)
        check(clock.observerCount == 1, "Repeated enabling must not create duplicate trackers")
        for frame in 1...120 { clock.advance(to: 101 + Double(frame) / 120) }
        check(sampleCount == 120 && deliveryCount == 120, "Menu tracking must run at 120 simulated frames, without a 10 fps cap")
        hover = false
        clock.advance(to: 103)
        check(sampleCount == 120, "No window scan is needed away from the menu")
        hover = true; snapshotAvailable = false
        clock.advance(to: 104)
        check(deliveryCount == 120, "A failed metadata query must not hide the current menu")
        tracking.setEnabled(false)
        clock.advance(to: 105)
        check(sampleCount == 121 && clock.observerCount == 0, "Leaving fullscreen must stop the fast sampler")
        let screen = CGRect(x: -1920, y: -100, width: 1920, height: 1080)
        check(FullscreenMenuCorners.pointerIsNearMenu(CGPoint(x: -1000, y: 970), screenFrame: screen), "Pointer gating must support displaced displays")
        check(!FullscreenMenuCorners.pointerIsNearMenu(CGPoint(x: 100, y: 970), screenFrame: screen), "Another display's pointer must not trigger a scan")
        check(!FullscreenMenuCorners.pointerIsNearMenu(CGPoint(x: -1000, y: 100), screenFrame: screen), "Interior pointers must not trigger a scan")

        let window = RecordingAttachment()
        let pinned = window.collectionBehavior
        let desktop: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
        let restored = OverlayAttachmentRestoration.restore(window, behavior: desktop, level: .init(rawValue: 19), move: {
            check(!window.collectionBehavior.contains(.canJoinAllSpaces), "Remove sticky membership before moving out of the overlay Space")
            return true
        })
        check(restored && window.collectionBehavior == desktop && window.level.rawValue == 19,
              "Desktop glow must regain its original behavior and level")
        check(window.history.first?.contains(.canJoinAllSpaces) == false && window.history.last?.contains(.canJoinAllSpaces) == true,
              "AppKit must receive a real false-to-true all-Spaces transition")
        window.collectionBehavior = pinned
        window.level = .init(rawValue: 1000)
        check(!OverlayAttachmentRestoration.restore(window, behavior: desktop, level: .init(rawValue: 19), move: { false }),
              "Failed moves must remain retryable")
        check(window.collectionBehavior == pinned && window.level.rawValue == 1000, "Failed restoration must roll back the pinned state")
        check(clock.observerCount == 0, "All frame callbacks must stop when tracking stops")
        check(NSApp == nil, "Tests must leave the desktop untouched")
        if failures.isEmpty {
            print("PASS: normal corner-color matching, unchanged gaming palette, headless 120 Hz tracking and fullscreen attachment restoration")
        } else {
            for failure in failures { print("FAIL:", failure) }
            exit(1)
        }
    }
}
