import AppKit

// xcrun swiftc Tests/SpacePresentationTests.swift Rounder/DisplaySpaceState.swift \
//   Rounder/NSScreen+DisplayInfo.swift Rounder/CornerGeometry.swift \
//   Rounder/CornerOverlayWindow.swift Rounder/GamingGlow.swift \
//   -o /tmp/rounder-space-presentation-tests
// Run in a logged-in macOS UI session.

enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }

@main
struct SpacePresentationTests {
    static func main() {
        let data: [[String: Any]] = [
            ["Display Identifier": "A", "Current Space": ["type": 0], "Spaces": [["type": 4]]],
            ["Display Identifier": "B", "Current Space": ["type": 4]],
            ["Display Identifier": "Main", "Current Space": ["type": 4]],
            ["Display Identifier": "C", "Current Space": ["type": 2]],
            ["Display Identifier": "D"]
        ]
        precondition(DisplaySpaceState.fullScreenIdentifiers(in: data) == ["B", "Main"])
        precondition(DisplaySpaceState.fullScreenIdentifiers(in: []).isEmpty)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        guard let screen = NSScreen.screens.first else { fatalError("A display is required") }
        var normal = screen.frame
        normal.size.height -= 30
        let size: CGFloat = 20
        let window = CornerOverlayWindow(
            corner: CornerGeometry.windowOrigin(in: normal, corner: .topLeft, cornerSize: size),
            size: size, radius: size, color: .clear, cornerType: ScreenCorner.topLeft.drawingCorner
        )
        let number = window.windowNumber
        window.updatePlacement(in: screen.frame, animated: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        precondition(abs(window.frame.maxY - screen.frame.maxY) < 0.01)
        precondition(window.windowNumber == number, "Animation must reuse the same overlay")
        window.updatePlacement(in: normal, animated: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        precondition(abs(window.frame.maxY - normal.maxY) < 0.01)
        window.updateGeometry(radius: 35, cutoutStyle: .rounded)
        precondition(abs(window.frame.maxY - normal.maxY) < 0.01, "Radius changes must use the updated anchor")
        window.prepareForClose()
        window.close()
        print("PASS: per-display fullscreen Space parsing, animated top-edge round trip and stable radius anchor")
    }
}
