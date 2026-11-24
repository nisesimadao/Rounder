import AppKit
import QuartzCore

/// Shares the top-edge gradient, corner colors and phase; no independent palette.
final class MenuBarBackgroundView: NSView {
    private var rainbowLayer: CAGradientLayer?
    private var cornerSize: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setGamingMode(_ enabled: Bool, speed: Double, cornerSize: CGFloat) {
        self.cornerSize = cornerSize
        rainbowLayer?.removeAllAnimations()
        rainbowLayer?.removeFromSuperlayer()
        rainbowLayer = nil
        guard enabled, let layer else { return }
        let rainbow = CAGradientLayer()
        rainbow.frame = bounds
        rainbow.startPoint = CGPoint(x: 0, y: 0.5)
        rainbow.endPoint = CGPoint(x: 1, y: 0.5)
        rainbow.locations = GamingGlowClock.topGradientLocations(width: bounds.width, cornerSize: cornerSize)
        layer.addSublayer(rainbow)
        GamingGlowClock.addRainbowAnimation(to: rainbow, baseHue: ScreenCorner.topLeft.gamingBaseHue, speed: speed, menuBar: true)
        rainbowLayer = rainbow
    }

    func updateCornerSize(_ cornerSize: CGFloat) {
        self.cornerSize = cornerSize
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rainbowLayer?.frame = bounds
        rainbowLayer?.locations = GamingGlowClock.topGradientLocations(width: bounds.width, cornerSize: cornerSize)
        CATransaction.commit()
    }
}
