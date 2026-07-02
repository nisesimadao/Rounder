//
//  GamingGlow.swift
//  Rounder
//
//  スーパーゲーミングモードの「ふち発光」。スクリーン全体を覆う1枚の透明ウィンドウに
//  各辺の CAGradientLayer を置き、色を Core Animation でレインボーに巡回させる。
//  GPU 合成なので draw() もタイマーも使わず、以前のCPUシャドウ描画のような重さは出ない。
//  枠線（バー）は描かず、内側へにじむ Bloom（グラデーション）のみ。
//

import Cocoa

enum ScreenEdge: Int, CaseIterable { case top, bottom, left, right }

/// スクリーン全体を覆うゲーミング発光ウィンドウ（1スクリーンにつき1枚）。
final class GamingGlowWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(screenFrame: NSRect, speed: Double, glowIntensity: Double) {
        super.init(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = GamingGlowView(size: screenFrame.size, speed: speed, glowIntensity: glowIntensity)
        orderFront(nil)
    }

    func prepareForClose() {
        (contentView as? GamingGlowView)?.stop()
    }
}

final class GamingGlowView: NSView {
    private let speed: Double
    private let glowIntensity: Double
    /// ふちから内側へ届く光の幅（intensity で広がる）
    private let reach: CGFloat
    private var edgeLayers: [CAGradientLayer] = []

    init(size: CGSize, speed: Double, glowIntensity: Double) {
        self.speed = max(0.1, speed)
        self.glowIntensity = glowIntensity
        // ふちから内側へ届く光の幅。人工的な光っぽく、やや狭めで強く。
        self.reach = 90 + CGFloat(glowIntensity) * 45
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.masksToBounds = false
        setupLayers(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { false }

    private func setupLayers(size: CGSize) {
        let w = size.width, h = size.height
        // 各辺: (フレーム, グラデーションの明→暗の向き)
        let specs: [(rect: CGRect, start: CGPoint, end: CGPoint)] = [
            (CGRect(x: 0, y: h - reach, width: w, height: reach), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0)), // top
            (CGRect(x: 0, y: 0, width: w, height: reach), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)),         // bottom
            (CGRect(x: 0, y: 0, width: reach, height: h), CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)),         // left
            (CGRect(x: w - reach, y: 0, width: reach, height: h), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5)), // right
        ]

        let duration = CornerOverlayConstants.baseColorAnimationDuration / speed
        let keyframes = rainbowKeyframes()

        for (index, spec) in specs.enumerated() {
            let gradient = CAGradientLayer()
            gradient.frame = spec.rect
            gradient.type = .axial
            gradient.startPoint = spec.start
            gradient.endPoint = spec.end
            // 明るい芯 → 素早く減衰、で「光源」っぽく
            gradient.locations = [0.0, 0.3, 1.0]
            gradient.colors = keyframes.first
            layer?.addSublayer(gradient)
            edgeLayers.append(gradient)

            let animation = CAKeyframeAnimation(keyPath: "colors")
            animation.values = keyframes
            animation.duration = duration
            animation.repeatCount = .infinity
            animation.calculationMode = .linear
            animation.isRemovedOnCompletion = false
            // 辺ごとに位相をずらして、色がふちを流れて回るように見せる
            animation.timeOffset = duration * Double(index) / 4.0
            gradient.add(animation, forKey: "rainbow")
        }
    }

    /// レインボー1周分のグラデーション色配列（明→中→透明の3ストップ）
    private func rainbowKeyframes() -> [[CGColor]] {
        let steps = 60
        let alphaEdge = min(1.0, 0.95 * glowIntensity)
        let alphaMid = alphaEdge * 0.45
        var values: [[CGColor]] = []
        values.reserveCapacity(steps + 1)
        for i in 0...steps {
            let hue = Double(i % steps) / Double(steps)
            let color = NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            values.append([
                color.withAlphaComponent(alphaEdge).cgColor,
                color.withAlphaComponent(alphaMid).cgColor,
                color.withAlphaComponent(0.0).cgColor,
            ])
        }
        return values
    }

    func stop() {
        edgeLayers.forEach { $0.removeAllAnimations() }
    }

    deinit {
        stop()
    }
}
