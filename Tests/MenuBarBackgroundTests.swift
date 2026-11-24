import AppKit

// Run in a logged-in macOS UI session:
// xcrun swiftc Tests/MenuBarBackgroundTests.swift Rounder/MenuBarBackgroundWindow.swift \
//   Rounder/MenuBarBackgroundView.swift Rounder/CornerGeometry.swift \
//   Rounder/CornerOverlayWindow.swift Rounder/GamingGlow.swift -o /tmp/rounder-menu-background-tests
// /tmp/rounder-menu-background-tests

enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }

@main
struct MenuBarBackgroundTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        guard let screen = NSScreen.screens.first else { fatalError("A display is required") }
        let window = MenuBarBackgroundWindow(screen: screen, displayID: 1)
        precondition(!window.collectionBehavior.contains(.transient), "Menu background must not hide ahead of screen-pinned corners")
        precondition(window.collectionBehavior.contains(.stationary), "Mission Control coordinator must own visibility timing")
        precondition(!window.collectionBehavior.contains(.managed), "Menu background must not appear as an app thumbnail")
        precondition(window.collectionBehavior.contains(.canJoinAllSpaces))
        precondition(window.ignoresMouseEvents, "System menu items must remain clickable")
        precondition(!window.canBecomeKey && !window.canBecomeMain)
        precondition(window.level.rawValue == NSWindow.Level.statusBar.rawValue - 1)
        if let expected = CornerGeometry.menuBarFrame(screenFrame: screen.frame, visibleFrame: screen.visibleFrame) {
            precondition(window.frame == expected, "Menu background must stay within the reserved menu bar")
            precondition(window.isVisible)
            let number = window.windowNumber
            for _ in 0..<10 { window.updatePlacement(on: screen) }
            precondition(window.windowNumber == number, "Placement refresh must reuse the same window")
            precondition(window.frame == expected)
        } else {
            precondition(!window.isVisible, "Auto-hidden menu bars must not obscure application content")
        }
        window.close()
        print("PASS: Mission Control behavior, menu click-through, window level and placement")
    }
}
