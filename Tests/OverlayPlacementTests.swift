import AppKit

// Compile the production placement and screen-monitor code with recording
// windows so Space/screen notifications cannot silently reintroduce rebuilds.
// xcrun swiftc Tests/OverlayPlacementTests.swift \
//   Rounder/AppDelegate+OverlayPlacement.swift Rounder/ScreenMonitor.swift \
//   Rounder/NSScreen+DisplayInfo.swift Rounder/CornerGeometry.swift \
//   -o /tmp/rounder-placement-tests
// /tmp/rounder-placement-tests

enum CornerType { case topLeft, topRight, bottomLeft, bottomRight }
enum CornerCutoutStyle { case rounded, squircle, polygon }
enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }

final class RecordingOverlay {
    let overlayDisplayID: CGDirectDisplayID?
    var placements: [NSRect] = []
    init(displayID: CGDirectDisplayID) { overlayDisplayID = displayID }
    func updatePlacement(in frame: NSRect) { placements.append(frame) }
}
final class AppDelegate {
    var overlayScreenFrames: [CGDirectDisplayID: NSRect] = [:]
    var overlayExcludesMenuBar = false
    var overlayWindows: [RecordingOverlay] = []
    var glowWindows: [RecordingOverlay] = []
    var rebuilds = 0
    func recreateOverlayWindows() { rebuilds += 1 }
}

@main
struct OverlayPlacementTests {
    static func main() {
        let screens = NSScreen.screens
        guard let screen = screens.first, let displayID = screen.displayID else {
            fatalError("Run in a logged-in macOS display session")
        }
        let delegate = AppDelegate()
        delegate.overlayScreenFrames = Dictionary(uniqueKeysWithValues: screens.compactMap {
            screen in screen.displayID.map { ($0, screen.frame) }
        })
        let corner = RecordingOverlay(displayID: displayID)
        let glow = RecordingOverlay(displayID: displayID)
        delegate.overlayWindows = [corner]
        delegate.glowWindows = [glow]
        for _ in 0..<10 { delegate.refreshOverlayScreenGeometry() }
        precondition(delegate.rebuilds == 0, "Unchanged displays must preserve window identity")
        precondition(corner.placements.isEmpty, "Screen-edge overlays do not need repositioning on Space changes")

        delegate.overlayExcludesMenuBar = true
        for _ in 0..<10 { delegate.refreshOverlayScreenGeometry() }
        precondition(delegate.rebuilds == 0, "Menu-bar exclusion must reposition existing windows instead of rebuilding")
        precondition(delegate.overlayWindows.first === corner && delegate.glowWindows.first === glow)
        let expected = CornerGeometry.overlayFrame(
            screenFrame: screen.frame, visibleFrame: screen.visibleFrame, excludeMenuBar: true
        )
        precondition(corner.placements.count == 10 && glow.placements.count == 10)
        precondition(corner.placements.allSatisfy { $0 == expected })
        precondition(glow.placements.allSatisfy { $0 == expected })

        ScreenMonitor.shared.startMonitoring(appDelegate: delegate)
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.7))
        ScreenMonitor.shared.stopMonitoring()
        precondition(delegate.rebuilds == 0, "Screen notification without topology changes must not rebuild")
        precondition(corner.placements.count == 11, "Screen notification must refresh placement")

        delegate.overlayScreenFrames = [:]
        delegate.refreshOverlayScreenGeometry()
        precondition(delegate.rebuilds == 1, "Actual display changes must still rebuild")
        print("PASS: repeated Space refreshes preserve windows; menu-bar exclusion updates corners and glow in place; screen notifications avoid unnecessary rebuilds")
    }
}
