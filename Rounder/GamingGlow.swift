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

    init(screenFrame: NSRect, speed: Double, glowIntensity: Double, bloomWidth: Double) {
        super.init(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        contentView = GamingGlowView(size: screenFrame.size, speed: speed, glowIntensity: glowIntensity, bloomWidth: bloomWidth)
        orderFront(nil)
    }

    func prepareForClose() {
        (contentView as? GamingGlowView)?.stop()
    }
}

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
}

final class GamingGlowView: NSView {
    private let speed: Double
    private let glowIntensity: Double
    private let bloomWidth: Double
    /// ふちから内側へ届く光の幅（bloomWidth で調整）
    private let reach: CGFloat
    private var edgeLayers: [CAGradientLayer] = []

    init(size: CGSize, speed: Double, glowIntensity: Double, bloomWidth: Double) {
        self.speed = max(0.1, speed)
        self.glowIntensity = glowIntensity
        self.bloomWidth = bloomWidth
        // 幅は bloomWidth で独立に調整（広さ）
        self.reach = 40 + CGFloat(bloomWidth) * 80
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.masksToBounds = false
        setupLayers(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { false }

    private func setupLayers(size: CGSize) {
        let w = size.width, h = size.height
        // 各辺: バンド矩形 / 色(hue)方向 start→end / 内側フェードのマスク方向 start→end / 周回上の基準hue
        // hue は「辺に沿って」並べ、時間で回転させる（＝虹がふちを順番に流れる）。
        let edges: [(band: CGRect, hueStart: CGPoint, hueEnd: CGPoint, maskStart: CGPoint, maskEnd: CGPoint, base: Double)] = [
            (CGRect(x: 0, y: h - reach, width: w, height: reach), CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0), 0.0),  // top: 左→右
            (CGRect(x: w - reach, y: 0, width: reach, height: h), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5), 0.25), // right: 上→下
            (CGRect(x: 0, y: 0, width: w, height: reach), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1), 0.5),          // bottom: 右→左
            (CGRect(x: 0, y: 0, width: reach, height: h), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), 0.75),         // left: 下→上
        ]

        let duration = CornerOverlayConstants.baseColorAnimationDuration / speed
        let alphaEdge = min(1.0, 0.9 * glowIntensity)

        for edge in edges {
            // 虹レイヤー：辺に沿って hue が並ぶ。colors を回転させて流す。
            let hueLayer = CAGradientLayer()
            hueLayer.frame = edge.band
            hueLayer.type = .axial
            hueLayer.startPoint = edge.hueStart
            hueLayer.endPoint = edge.hueEnd
            hueLayer.colors = hueColors(base: edge.base, t: 0)

            // 内側フェード（Bloomの形と濃さ）を alpha マスクで与える。
            // 一番はじ（画面の縁）から約1pxは必ず完全不透明にし、そこから内側へフェードする。
            let solidLoc = min(0.12, 1.5 / reach)
            let mask = CAGradientLayer()
            mask.frame = CGRect(origin: .zero, size: edge.band.size)
            mask.type = .axial
            mask.startPoint = edge.maskStart
            mask.endPoint = edge.maskEnd
            mask.locations = [0.0, NSNumber(value: solidLoc), 0.35, 1.0]
            mask.colors = [
                NSColor.white.cgColor,                                  // 画面の縁：完全不透明（必ず）
                NSColor.white.cgColor,                                  // 約1pxまで不透明
                NSColor.white.withAlphaComponent(alphaEdge).cgColor,    // Bloom本体（濃さ）
                NSColor.white.withAlphaComponent(0.0).cgColor,          // 内側：透明
            ]
            hueLayer.mask = mask

            layer?.addSublayer(hueLayer)
            edgeLayers.append(hueLayer)

            let anim = CAKeyframeAnimation(keyPath: "colors")
            anim.values = (0...GamingGlowClock.steps).map { hueColors(base: edge.base, t: Double($0) / Double(GamingGlowClock.steps)) }
            anim.duration = duration
            anim.repeatCount = .infinity
            anim.calculationMode = .linear
            anim.isRemovedOnCompletion = false
            anim.beginTime = hueLayer.convertTime(GamingGlowClock.anchor, from: nil)
            hueLayer.add(anim, forKey: "rainbow")
        }
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
        edgeLayers.forEach { $0.removeAllAnimations() }
    }

    deinit {
        stop()
    }
}
