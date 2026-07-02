//
//  GamingGlow.swift
//  Rounder
//
//  スーパーゲーミングモードの「ふち発光」。画面の各辺に細いバンド状の透明ウィンドウを
//  1本ずつ置き（1スクリーンにつき4枚）、CAGradientLayer の色を Core Animation で
//  レインボーに巡回させる。GPU 合成なので draw() もタイマーも使わず軽量。
//  全画面を覆う1枚方式に比べ、WindowServer の合成面積とレイヤーバッキングを
//  1桁小さく抑えられる（発光の見た目は同一）。
//  枠線（バー）は描かず、内側へにじむ Bloom（グラデーション）のみ。
//

import Cocoa

enum ScreenEdge: Int, CaseIterable { case top, bottom, left, right }

/// ゲーミング発光の色巡回を、角（CAShapeLayer）とふち（CAGradientLayer）で完全に同期させるための共有時刻。
/// 全レイヤーが同じ基準時刻から begin することで、角とBloomの色が一致する。
enum GamingGlowClock {
    /// 全レイヤー共通の基準時刻（初回アクセス時に一度だけ確定）。
    static let anchor: CFTimeInterval = CACurrentMediaTime()

    /// レインボー1周分の色（虹の hue を N 分割）。角・ふちで同じ進行を使う。
    static let steps = 120
    static func hue(at index: Int) -> Double { Double(index % steps) / Double(steps) }
    static func color(at index: Int) -> NSColor {
        NSColor(hue: hue(at: index), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    /// ふちから内側へ届く光の幅。プロファイル基準（24px）× 広さ設定。
    static func reach(bloomWidth: Double) -> CGFloat {
        max(5, 24 * CGFloat(bloomWidth))
    }
}

/// 画面の1辺ぶんのゲーミング発光バンドウィンドウ（1スクリーンにつき4枚）。
final class GamingGlowWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(screenFrame: NSRect, edge: ScreenEdge, speed: Double, glowIntensity: Double, bloomWidth: Double) {
        let reach = GamingGlowClock.reach(bloomWidth: bloomWidth)
        let bandFrame: NSRect
        switch edge {
        case .top:    bandFrame = NSRect(x: screenFrame.minX, y: screenFrame.maxY - reach, width: screenFrame.width, height: reach)
        case .bottom: bandFrame = NSRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: reach)
        case .left:   bandFrame = NSRect(x: screenFrame.minX, y: screenFrame.minY, width: reach, height: screenFrame.height)
        case .right:  bandFrame = NSRect(x: screenFrame.maxX - reach, y: screenFrame.minY, width: reach, height: screenFrame.height)
        }
        super.init(contentRect: bandFrame, styleMask: .borderless, backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = GamingGlowEdgeView(size: bandFrame.size, edge: edge, speed: speed, glowIntensity: glowIntensity)
        // アプリが非アクティブ（常時）でも確実に前面へ出す
        orderFrontRegardless()
    }

    func prepareForClose() {
        (contentView as? GamingGlowEdgeView)?.stop()
    }
}

/// 1辺ぶんの発光バンド。辺に沿って hue が並び、時間で回転して虹がふちを流れる。
final class GamingGlowEdgeView: NSView {
    private let edge: ScreenEdge
    private let speed: Double
    private let glowIntensity: Double
    private var hueLayer: CAGradientLayer?

    init(size: CGSize, edge: ScreenEdge, speed: Double, glowIntensity: Double) {
        self.edge = edge
        self.speed = max(0.1, speed)
        self.glowIntensity = glowIntensity
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        setupLayer(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { false }

    /// 辺ごとの hue 方向（辺に沿って周回順）・内側フェード方向・周回上の基準 hue
    private var spec: (hueStart: CGPoint, hueEnd: CGPoint, maskStart: CGPoint, maskEnd: CGPoint, base: Double) {
        switch edge {
        case .top:    return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0), 0.0)   // 左→右
        case .right:  return (CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5), 0.25)  // 上→下
        case .bottom: return (CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1), 0.5)   // 右→左
        case .left:   return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), 0.75)  // 下→上
        }
    }

    private func setupLayer(size: CGSize) {
        let spec = self.spec
        let duration = CornerOverlayConstants.baseColorAnimationDuration / speed

        // 画面の縁からの距離（reach=24px基準）と不透明度のプロファイル。
        // 一番はじ(≤1px)は必ず不透明、そこから 2px=50%,3px=30%,4px=25%… と急激に減衰。
        // 本体（1pxより内側）は「濃さ(glowIntensity)」でスケールする。
        let opacity = min(1.0, glowIntensity)
        let profile: [(px: Double, a: Double)] = [
            (0, 1.0), (1, 1.0), (2, 0.5), (3, 0.3), (4, 0.25), (6, 0.16), (9, 0.09), (14, 0.04), (24, 0.0),
        ]
        let maxPx = 24.0

        // 虹レイヤー：辺に沿って hue が並ぶ。colors を回転させて流す。
        let hueLayer = CAGradientLayer()
        hueLayer.frame = CGRect(origin: .zero, size: size)
        hueLayer.type = .axial
        hueLayer.startPoint = spec.hueStart
        hueLayer.endPoint = spec.hueEnd
        hueLayer.colors = hueColors(base: spec.base, t: 0)

        // 内側フェード（Bloomの形と濃さ）を alpha マスクで与える（急減衰プロファイル）。
        let mask = CAGradientLayer()
        mask.frame = CGRect(origin: .zero, size: size)
        mask.type = .axial
        mask.startPoint = spec.maskStart
        mask.endPoint = spec.maskEnd
        mask.locations = profile.map { NSNumber(value: $0.px / maxPx) }
        mask.colors = profile.map { p -> CGColor in
            let a = p.px <= 1.0 ? 1.0 : p.a * opacity
            return NSColor.white.withAlphaComponent(a).cgColor
        }
        hueLayer.mask = mask

        layer?.addSublayer(hueLayer)
        self.hueLayer = hueLayer

        let anim = CAKeyframeAnimation(keyPath: "colors")
        anim.values = (0...GamingGlowClock.steps).map { hueColors(base: spec.base, t: Double($0) / Double(GamingGlowClock.steps)) }
        anim.duration = duration
        anim.repeatCount = .infinity
        anim.calculationMode = .linear
        anim.isRemovedOnCompletion = false
        // 全辺・全角を共有時刻から begin して色を完全同期
        anim.beginTime = hueLayer.convertTime(GamingGlowClock.anchor, from: nil)
        hueLayer.add(anim, forKey: "rainbow")
    }

    /// 1つの辺に沿った hue 配列（周回上の base から 0.25周ぶん）。t で全体を回転させる。
    private func hueColors(base: Double, t: Double) -> [CGColor] {
        let stops = 6
        return (0...stops).map { s in
            let hue = (base + t + Double(s) / Double(stops) * 0.25).truncatingRemainder(dividingBy: 1.0)
            return NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor
        }
    }

    func stop() {
        hueLayer?.removeAllAnimations()
    }

    deinit {
        stop()
    }
}
