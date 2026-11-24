import AppKit

// xcrun swiftc Tests/MissionControlTests.swift Rounder/MissionControlMonitor.swift \
//   Rounder/AppDelegate+MissionControl.swift Rounder/NSScreen+DisplayInfo.swift \
//   -o /tmp/rounder-mission-control-tests

final class TestOverlay {
    var overlayDisplayID: CGDirectDisplayID?
    var isTopCorner: Bool
    var isTopEdge: Bool
    var durations: [TimeInterval] = []
    var alphaValue: CGFloat = 1 {
        didSet { durations.append(NSAnimationContext.current.duration) }
    }
    func animator() -> TestOverlay { self }
    init(_ display: CGDirectDisplayID, top: Bool) {
        overlayDisplayID = display
        isTopCorner = top
        isTopEdge = top
    }
}
final class TestBar {
    let overlayDisplayID: CGDirectDisplayID
    var durations: [TimeInterval] = []
    var alphaValue: CGFloat = 1 {
        didSet { durations.append(NSAnimationContext.current.duration) }
    }
    func animator() -> TestBar { self }
    init(_ display: CGDirectDisplayID) { overlayDisplayID = display }
}
final class AppDelegate {
    var overlayExcludesMenuBar = true
    var overlayWindows: [TestOverlay] = []
    var glowWindows: [TestOverlay] = []
    var menuBarBackgroundWindows: [TestBar] = []
}

@main
struct MissionControlTests {
    static func main() {
        _ = NSApplication.shared
        let bounds: [CGDirectDisplayID: CGRect] = [
            1: CGRect(x: 0, y: 0, width: 1680, height: 1050),
            2: CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        ]
        func shield(_ pid: pid_t, _ display: CGDirectDisplayID, layer: Int = 18,
                    name: String? = nil) -> [String: Any] {
            var window: [String: Any] = [kCGWindowOwnerPID as String: pid,
                kCGWindowLayer as String: layer,
                kCGWindowBounds as String: bounds[display]!.dictionaryRepresentation,
                kCGWindowAlpha as String: 1]
            if let name { window[kCGWindowName as String] = name }
            return window
        }
        let dock = shield(100, 1)
        let manager = shield(200, 2, name: "ExposeShieldWindow")
        let hosts: Set<pid_t> = [100, 200]
        precondition(MissionControlMonitor.activeDisplays(windows: [dock, manager], hostPIDs: hosts, screenBounds: bounds) == [1, 2])
        precondition(MissionControlMonitor.activeDisplays(windows: [shield(999, 1)], hostPIDs: hosts, screenBounds: bounds).isEmpty)
        precondition(MissionControlMonitor.activeDisplays(windows: [shield(100, 1, layer: 20)], hostPIDs: hosts, screenBounds: bounds).isEmpty)
        precondition(MissionControlMonitor.activeDisplays(windows: [shield(200, 1, name: "Unrelated Panel")], hostPIDs: hosts, screenBounds: bounds).isEmpty)
        var small = dock
        small[kCGWindowBounds as String] = CGRect(x: 0, y: 0, width: 100, height: 100).dictionaryRepresentation
        precondition(MissionControlMonitor.activeDisplays(windows: [small], hostPIDs: hosts, screenBounds: bounds).isEmpty)
        var transparent = dock
        transparent[kCGWindowAlpha as String] = 0.0
        precondition(MissionControlMonitor.activeDisplays(windows: [transparent], hostPIDs: hosts, screenBounds: bounds).isEmpty)

        let delegate = AppDelegate()
        let top = TestOverlay(1, top: true)
        let bottom = TestOverlay(1, top: false)
        let other = TestOverlay(2, top: true)
        let topGlow = TestOverlay(1, top: true)
        let bottomGlow = TestOverlay(1, top: false)
        let bar = TestBar(1)
        delegate.overlayWindows = [top, bottom, other]
        delegate.glowWindows = [topGlow, bottomGlow]
        delegate.menuBarBackgroundWindows = [bar]
        delegate.applyMissionControlVisibility([1])
        precondition(top.alphaValue == 0 && topGlow.alphaValue == 0 && bar.alphaValue == 0)
        precondition(top.durations.last == bar.durations.last && topGlow.durations.last == bar.durations.last,
                     "Strip and top corners must use the same fade duration")
        precondition(bottom.alphaValue == 1 && bottomGlow.alphaValue == 1 && other.alphaValue == 1)
        delegate.applyMissionControlVisibility([])
        precondition(top.alphaValue == 1 && topGlow.alphaValue == 1 && bar.alphaValue == 1)
        delegate.applyMissionControlVisibility([1], animated: false)
        precondition(top.durations.last == 0 && bar.durations.last == 0, "Initial presentation must not flash visible overlays")
        delegate.overlayExcludesMenuBar = false
        delegate.applyMissionControlVisibility([1])
        precondition(top.alphaValue == 1 && topGlow.alphaValue == 1 && bar.alphaValue == 0)
        print("PASS: Mission Control detection across displays, top-only suppression and restoration")
    }
}
