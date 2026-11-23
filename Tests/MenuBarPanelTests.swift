import AppKit
import SwiftUI

// Run in a logged-in macOS UI session:
// xcrun swiftc Tests/MenuBarPanelTests.swift Rounder/MenuBarController.swift \
//   Rounder/MenuBarPanel.swift Rounder/MenuBarPanelRoot.swift Rounder/MenuBarPanelView.swift \
//   Rounder/CornerGeometry.swift Rounder/CornerOverlayWindow.swift Rounder/GamingGlow.swift \
//   -o /tmp/rounder-panel-tests
// /tmp/rounder-panel-tests
// Minimal application dependencies; compile the real controller, controls and overlays.
final class AppDelegate {
    func showSettings() {}
    func recreateOverlayWindows() {}
    func updateCornerGeometry(radius: Double, cutoutStyle: CornerCutoutStyle) {}
}
enum MenuBarVisibilityPreference {
    static var isVisible = true
    static let wasLaunchedAsLoginItem = true
}
struct RounderAppConstants {
    static let maxInstances = 3
    static let firstLaunchWindowSize = NSSize(width: 600, height: 500)
    static let minWindowSize = NSSize(width: 500, height: 450)
    static let settingsMinWindowSize = NSSize(width: 700, height: 600)
    static let defaultCornerRadius: Double = 20.0
    static let cornerSizePadding: CGFloat = 0.01
    static let settingsWindowSize = NSSize(width: 860, height: 820)
    static let threadSleepInterval: TimeInterval = 0.001
    static let cornerRadiusMin: Double = 0
    static let cornerRadiusMax: Double = 40
    static let cornerRadiusStep: Double = 1
}

// MARK: - UserDefaults Keys
struct UserDefaultsKeys {
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let cornerRadius = "cornerRadius"
    static let cornerColor = "cornerColor"
    static let isEnabled = "isEnabled"
    static let superGamingMode = "superGamingMode"
    static let gamingSpeed = "gamingSpeed"
    static let glowIntensity = "glowIntensity"
    static let bloomWidth = "bloomWidth"
    static let cornerCutoutStyle = "cornerCutoutStyle"
    static let topLeftEnabled = "topLeftEnabled"
    static let topRightEnabled = "topRightEnabled"
    static let bottomLeftEnabled = "bottomLeftEnabled"
    static let bottomRightEnabled = "bottomRightEnabled"
    static let pinToScreen = "pinToScreen"
    static let pinToDesktop = "pinToDesktop"
    static let excludeMenuBar = "excludeMenuBar"
    static let selectedDisplayIDs = "selectedDisplayIDs"
}

@main
struct PanelTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let controller = MenuBarController()
        let delegate = AppDelegate()
        controller.setupMenuBar(appDelegate: delegate)
        let item = Mirror(reflecting: controller).children.first { $0.label == "statusItem" }!.value as! NSStatusItem?
        guard let button = item?.button else { fatalError("Missing status button") }
        for _ in 0..<5 {
            button.performClick(nil)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let panel = app.windows.first { $0 is MenuBarPanel && $0.isVisible }
            precondition(panel != nil, "Click must open the panel")
            precondition(panel!.frame.height >= 300, "The real control panel must have room for all its sections")
            precondition(panel!.canBecomeKey, "Panel must support key controls")
            precondition(button.state == .on, "Open panel must select the status icon")
            button.performClick(nil)
            precondition(!panel!.isVisible, "Second click must close the panel")
            precondition(button.state == .off, "Closed panel must clear selected state")
            precondition(!button.isHighlighted, "Closed panel must clear the status highlight")
        }
        // A nonactivating panel can lose key status without an outside click.
        // It must not vanish while the status button finishes tracking.
        button.performClick(nil)
        let keyPanel = app.windows.first { $0 is MenuBarPanel && $0.isVisible }!
        let transient = NSPanel(contentRect: NSRect(x: 100, y: 100, width: 100, height: 100),
                                styleMask: [.nonactivatingPanel], backing: .buffered, defer: false)
        transient.isReleasedWhenClosed = false
        transient.makeKeyAndOrderFront(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(keyPanel.isVisible, "Key-status changes alone must not dismiss the menu")
        transient.close()
        button.performClick(nil)

        // AppKit may hide an all-Spaces panel without our close action.
        // The first click afterwards must reopen it, not just clear the pointer.
        button.performClick(nil)
        let hiddenPanel = app.windows.first { $0 is MenuBarPanel && $0.isVisible }!
        hiddenPanel.orderOut(nil)
        button.performClick(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let reopened = app.windows.first { $0 is MenuBarPanel && $0.isVisible }
        precondition(reopened != nil, "One click must recover a system-hidden panel")
        precondition(button.state == .on, "Recovered panel must select the status icon")
        button.performClick(nil)

        button.performClick(nil)
        let openPanel = app.windows.first { $0 is MenuBarPanel && $0.isVisible }!
        MenuBarVisibilityPreference.isVisible = false
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(!openPanel.isVisible, "Hiding the icon must close its panel")
        precondition(button.state == .off, "Removing the icon must clear its selected state")
        print("PASS: five status-icon open/close cycles; key-capable panel; highlight follows visibility")
    }
}
