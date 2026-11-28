import AppKit
import QuartzCore

// xcrun swiftc Tests/GamingMenuBarTests.swift Rounder/MenuBarBackgroundWindow.swift Rounder/MenuBarBackgroundAppearance.swift \
//   Rounder/MenuBarBackgroundView.swift Rounder/DesktopSpaceMembership.swift Rounder/CornerGeometry.swift \
//   Rounder/CornerOverlayWindow.swift Rounder/GamingGlow.swift -o /tmp/rounder-gaming-menu-tests

enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }

@main
struct GamingMenuBarTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        guard let screen = NSScreen.screens.first else { fatalError("A display is required") }
        let bar = MenuBarBackgroundWindow(screen: screen, displayID: 1)
        let number = bar.windowNumber
        bar.setGamingMode(true, speed: 2, cornerSize: 40)
        let glow = GamingGlowWindow(screenFrame: screen.frame, edge: .top, speed: 2,
                                    glowIntensity: 1, bloomWidth: 1, cornerSize: 40)
        func gradient(_ window: NSWindow) -> CAGradientLayer {
            window.contentView!.layer!.sublayers!.compactMap { $0 as? CAGradientLayer }.first!
        }
        let bandLayer = gradient(bar), glowLayer = gradient(glow)
        let bandAnimation = bandLayer.animation(forKey: "rainbow") as! CAKeyframeAnimation
        let glowAnimation = glowLayer.animation(forKey: "rainbow") as! CAKeyframeAnimation
        precondition(bandAnimation.duration == 1.5 && bandAnimation.duration == glowAnimation.duration)
        precondition(bandLayer.locations == glowLayer.locations)
        precondition(abs(bandLayer.convertTime(bandAnimation.beginTime, to: nil) - GamingGlowClock.anchor) < 0.00001)
        precondition(abs(glowLayer.convertTime(glowAnimation.beginTime, to: nil) - GamingGlowClock.anchor) < 0.00001)
        let bandFrames = bandAnimation.values as! [[CGColor]]
        let glowFrames = glowAnimation.values as! [[CGColor]]
        let left = GamingGlowClock.cornerColors(baseHue: ScreenCorner.topLeft.gamingBaseHue)
        let right = GamingGlowClock.cornerColors(baseHue: ScreenCorner.topRight.gamingBaseHue)
        precondition(bandFrames.count == GamingGlowClock.steps + 1)
        for i in bandFrames.indices {
            precondition(glowFrames[i].first!.components == left[i].components,
                         "Top edge's left end must match the top-left corner at every animation frame")
            precondition(glowFrames[i].last!.components == right[i].components,
                         "Top edge's right end must match the top-right corner at every animation frame")
            precondition(bandFrames[i].map(\.components) == glowFrames[i].map { GamingGlowClock.menuBarColor($0).components },
                         "Menu strip must share the glow cycle with only the contrast adjustment applied")
        }
        let oldLocations = bandLayer.locations
        bar.updateCornerSize(72)
        glow.updateCornerSize(72)
        precondition(bandLayer.locations == glowLayer.locations && bandLayer.locations != oldLocations)
        precondition(bandLayer.animation(forKey: "rainbow")!.beginTime == bandAnimation.beginTime,
                     "Radius/shape changes must not restart the shared color cycle")
        precondition(bar.ignoresMouseEvents && bar.level.rawValue < CGWindowLevelForKey(.mainMenuWindow))
        bar.setGamingMode(false, speed: 2, cornerSize: 72)
        precondition(bar.contentView!.layer!.sublayers?.contains { $0 is CAGradientLayer } != true)
        precondition(bar.backgroundColor.isEqual(NSColor.black) && bar.windowNumber == number)
        precondition(GamingGlowClock.topGradientLocations(width: 0, cornerSize: 72).allSatisfy { $0.doubleValue.isFinite })
        glow.prepareForClose()
        glow.close()
        bar.prepareForClose()
        bar.close()
        print("PASS: menu strip, glow and corners share every color frame, speed and phase; live radius preserves sync; normal mode restores black")
    }
}
