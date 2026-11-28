import AppKit

// Run in a logged-in macOS UI session:
// xcrun swiftc Tests/MenuBarBackgroundTests.swift Rounder/MenuBarBackgroundWindow.swift Rounder/MenuBarBackgroundAppearance.swift \
//   Rounder/MenuBarBackgroundView.swift Rounder/DesktopSpaceMembership.swift Rounder/CornerGeometry.swift \
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
        // Model a system menu surface at its actual WindowServer level. A
        // freshly raised background must stay behind it even when created later.
        let menu = NSWindow(contentRect: NSRect(x: screen.frame.minX + 40, y: screen.frame.maxY - 25,
                                               width: 120, height: 20),
                            styleMask: .borderless, backing: .buffered, defer: false)
        menu.isReleasedWhenClosed = false
        menu.ignoresMouseEvents = true
        menu.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
        menu.orderFrontRegardless()
        let window = MenuBarBackgroundWindow(screen: screen, displayID: 1)
        precondition(!window.collectionBehavior.contains(.transient), "Menu background must not hide ahead of screen-pinned corners")
        precondition(window.collectionBehavior.contains(.stationary), "Mission Control coordinator must own visibility timing")
        precondition(!window.collectionBehavior.contains(.managed), "Menu background must not appear as an app thumbnail")
        if window.usesDesktopSpaceMembership {
            precondition(!window.collectionBehavior.contains(.canJoinAllSpaces))
            precondition(!window.collectionBehavior.contains(.fullScreenAuxiliary))
        } else {
            precondition(window.collectionBehavior.contains(.canJoinAllSpaces))
        }
        precondition(window.ignoresMouseEvents, "System menu items must remain clickable")
        precondition(!window.canBecomeKey && !window.canBecomeMain)
        precondition(window.level.rawValue < CGWindowLevelForKey(.mainMenuWindow), "Black strip must never share the main menu level")
        precondition(window.level.rawValue < CGWindowLevelForKey(.statusWindow))
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
        if window.usesDesktopSpaceMembership {
            let initialFrame = window.frame
            let number = window.windowNumber
            // A fullscreen notification must not order the outgoing desktop's
            // strip out, nor rebuild or reposition it while it slides away.
            window.updatePlacement(on: screen, isFullScreen: true)
            precondition(window.isVisible && window.frame == initialFrame)
            precondition(window.windowNumber == number)
            window.updatePlacement(on: screen, isFullScreen: false)
            precondition(window.windowNumber == number)
        }
        window.orderFrontRegardless()
        let ordered = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
        let ids = ordered.compactMap { $0[kCGWindowNumber as String] as? Int }
        // Offscreen Spaces have separate ordering lists. Only compare surfaces
        // actually being composited together on the current desktop.
        if let menuIndex = ids.firstIndex(of: menu.windowNumber),
           let backgroundIndex = ids.firstIndex(of: window.windowNumber) {
            precondition(menuIndex < backgroundIndex,
                         "Raising the background must never cover a system-level menu surface")
        }
        window.setCornerColor(.white)
        precondition(window.backgroundColor.isEqual(NSColor.white))
        window.setCornerColor(.red)
        precondition(window.backgroundColor.isEqual(NSColor.red))
        window.setGamingMode(false, speed: 1, cornerSize: 20)
        precondition(window.backgroundColor.isEqual(NSColor.red))
        menu.close()
        window.close()
        print("PASS: Mission Control behavior, menu click-through, window level and placement")
    }
}
