//
//  CornerOverlayWindow.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import QuartzCore
import CoreGraphics
import CoreVideo

// MARK: - Constants
/// CornerOverlayWindowで使用する定数値を管理する構造体
struct CornerOverlayConstants {
    /// レインボーカラーの数
    static let rainbowColorCount = 360
    /// レインボーカラーの彩度（ゲーミングらしいビビッドさのため最大値）
    static let rainbowSaturation = 1.0
    /// レインボーカラーの明度（ゲーミングらしいビビッドさのため最大値）
    static let rainbowBrightness = 1.0
    /// ブルームエフェクトの彩度
    static let bloomSaturation = 1.0
    /// ブルームエフェクトの明度
    static let bloomBrightness = 1.0
    /// コンテンツサイズのオフセット（ウィンドウ＝コンテンツ同サイズのため 0。
    /// 旧実装のシャドウ用余白の名残で、参照箇所の互換のために残している）
    static let contentSizeOffset: CGFloat = 0
    /// ゲーミングモードの更新間隔（秒）
    static let gamingUpdateInterval: TimeInterval = 0.016
    /// スレッドのスリープ間隔（秒）
    static let threadSleepInterval: TimeInterval = 0.001
    /// 色アニメーションの基本期間（秒）
    static let baseColorAnimationDuration: TimeInterval = 3.0
    /// ブルームレイヤーのサイズ
    static let bloomLayerSize: CGFloat = 6
    /// ブルームシャドウ半径
    static let bloomShadowRadius: CGFloat = 50
    /// ブルームシャドウ透明度
    static let bloomShadowOpacity: Float = 1.0
    /// グロウフェーズの増分
    static let glowPhaseIncrement: Double = 0.05
    /// 円周率の2倍
    static let twoPi: Double = 2 * .pi
}

class CornerOverlayWindow: NSWindow {
    private var size: CGFloat
    private var radius: CGFloat
    private var color: NSColor
    private var cutoutStyle: CornerCutoutStyle
    private let cornerType: CornerType
    /// 物理的な画面上の角。描画用 CornerType は上下が反転しているため別に保持する。
    private let screenCorner: ScreenCorner
    /// 初期生成時の物理的な角座標。ライブ更新時は window.screen を参照せず、
    /// この点を固定したままウィンドウだけを伸縮する。
    private let anchorPoint: CGPoint

    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }

    init(corner: CGPoint, size: CGFloat, radius: CGFloat, color: NSColor = .black, cutoutStyle: CornerCutoutStyle = .rounded, cornerType: CornerType) {
        let initialFrame = NSRect(origin: corner, size: CGSize(width: size, height: size))
        let screenCorner = cornerType.screenCorner

        self.size = size
        self.radius = radius
        self.color = color
        self.cutoutStyle = cutoutStyle
        self.cornerType = cornerType
        self.screenCorner = screenCorner
        self.anchorPoint = CornerGeometry.anchorPoint(for: initialFrame, corner: screenCorner)

        // ウィンドウは切り欠きコンテンツと同サイズ（描画はすべて境界内に収まるため余白は不要。
        // 余白があるとその分レイヤーバッキングと合成面積を無駄に消費する）
        super.init(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        // ARCがライフタイムを管理するようにする。これを false にしないと、
        // overlayWindows 配列で強参照を保持したまま close() を呼んだ際に過剰解放となり、
        // 「再起動なしで適用」した瞬間にクラッシュする（＝適用されなくなる）原因になる。
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let contentView = CornerOverlayView(radius: radius, color: color, cutoutStyle: cutoutStyle, contentSize: size, cornerType: cornerType)
        contentView.frame = NSRect(origin: .zero, size: NSSize(width: size, height: size))
        contentView.autoresizingMask = [.width, .height]
        self.contentView = contentView

        // アプリが非アクティブ（常時）でも確実に前面へ出す
        orderFrontRegardless()
    }

    /// Radius / shape だけを変更するときの軽量更新。
    /// NSWindow 自体は破棄せず、初期生成時の物理角を固定したまま frame と path を更新する。
    func updateGeometry(radius: CGFloat, cutoutStyle: CornerCutoutStyle) {
        let newSize = CornerGeometry.cornerSize(radius: radius, style: cutoutStyle)
        guard radius != self.radius || cutoutStyle != self.cutoutStyle || newSize != size else {
            return
        }

        self.radius = radius
        self.cutoutStyle = cutoutStyle
        self.size = newSize

        let newOrigin = CornerGeometry.windowOrigin(
            anchoredAt: anchorPoint,
            corner: screenCorner,
            cornerSize: newSize
        )
        let newFrame = NSRect(
            origin: newOrigin,
            size: NSSize(width: newSize, height: newSize)
        )

        // display:false にして、古いView状態で途中描画されるのを避ける。
        // View側の状態更新後に needsDisplay で次の描画を要求する。
        setFrame(newFrame, display: false)
        (contentView as? CornerOverlayView)?.updateGeometry(
            radius: radius,
            cutoutStyle: cutoutStyle,
            contentSize: newSize
        )
    }
    
    func setGamingMode(_ enabled: Bool, speed: Double, baseHue: Double = 0) {
        (contentView as? CornerOverlayView)?.setGamingMode(enabled, speed: speed, baseHue: baseHue)
    }

    func prepareForClose() {
        (contentView as? CornerOverlayView)?.setGamingMode(false, speed: 1, baseHue: 0)
    }
}

class CornerOverlayView: NSView {
    private var radius: CGFloat
    private var color: NSColor
    private var cutoutStyle: CornerCutoutStyle
    private var contentSize: CGFloat
    /// 描画する角の種別。生成時に確定させる（window.screen からの推測に頼らない）。
    /// マルチモニターでオーバーレイが隣接ディスプレイにまたがると window.screen が
    /// 隣のディスプレイを返すことがあり、角が誤って描画されるのを防ぐ。
    private let cornerType: CornerType
    /// ゲーミング時：角の切り欠き形状を虹色にアニメーションさせるレイヤー（GPU合成）
    private var isGaming = false
    private var gamingLayer: CAShapeLayer?
    /// Squircleパスのキャッシュ（radiusとcontentSizeが変わったら再計算）
    private var cachedSquirclePath: CGPath?
    private var cachedSquircleRadius: CGFloat = 0
    private var cachedSquircleSize: CGFloat = 0

    init(radius: CGFloat, color: NSColor, cutoutStyle: CornerCutoutStyle, contentSize: CGFloat, cornerType: CornerType) {
        self.radius = radius
        self.color = color
        self.cutoutStyle = cutoutStyle
        self.contentSize = contentSize
        self.cornerType = cornerType
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: contentSize, height: contentSize)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 既存Viewのidentityを保ったままRadius / shapeだけを更新する。
    /// Squircle cache はgeometry依存なので破棄し、Gaming中はCAShapeLayerのpathだけ差し替える。
    func updateGeometry(radius: CGFloat, cutoutStyle: CornerCutoutStyle, contentSize: CGFloat) {
        self.radius = radius
        self.cutoutStyle = cutoutStyle
        self.contentSize = contentSize

        cachedSquirclePath = nil
        cachedSquircleRadius = 0
        cachedSquircleSize = 0

        setFrameSize(NSSize(width: contentSize, height: contentSize))

        if let layer {
            layer.frame = bounds
        }

        if let gamingLayer {
            let offset = CornerOverlayConstants.contentSizeOffset
            let localBounds = bounds.isEmpty
                ? NSRect(x: 0, y: 0, width: contentSize, height: contentSize)
                : bounds

            gamingLayer.frame = NSRect(
                x: offset,
                y: offset,
                width: localBounds.width,
                height: localBounds.height
            )
            gamingLayer.path = gamingFillPath(in: localBounds)
            gamingLayer.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        }

        needsDisplay = true
    }

    /// ゲーミング時、角丸の「見えている部分（切り欠き形状）」を虹色に光らせる。
    /// draw() の黒マスクの代わりに、同じ形の CAShapeLayer を Core Animation で色巡回させる（軽量）。
    func setGamingMode(_ enabled: Bool, speed: Double, baseHue: Double = 0) {
        isGaming = enabled
        gamingLayer?.removeFromSuperlayer()
        gamingLayer = nil

        if enabled {
            wantsLayer = true
            guard let layer else {
                needsDisplay = true
                return
            }
            layer.masksToBounds = false
            layer.frame = bounds

            let offset = CornerOverlayConstants.contentSizeOffset
            // くり抜きは境界内に収まるパイ型パスで構成するため、masksToBounds は不要。
            // （ハードクリップは外周のアンチエイリアスを削り、画面のふちで1px欠けて見える原因になる）
            let localBounds = bounds.isEmpty ? NSRect(x: 0, y: 0, width: contentSize, height: contentSize) : bounds
            let shape = CAShapeLayer()
            shape.frame = NSRect(x: offset, y: offset, width: localBounds.width, height: localBounds.height)
            shape.path = gamingFillPath(in: localBounds)
            shape.fillRule = .evenOdd
            shape.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2

            let colors = rainbowCGColors(baseHue: baseHue)
            shape.fillColor = colors.first
            let animation = CAKeyframeAnimation(keyPath: "fillColor")
            animation.values = colors
            animation.duration = CornerOverlayConstants.baseColorAnimationDuration / max(0.1, speed)
            animation.repeatCount = .infinity
            animation.calculationMode = .linear
            animation.isRemovedOnCompletion = false
            layer.addSublayer(shape)
            // ふちのBloomと同じ共有時刻から begin して、角とBloomの色を一致させる
            animation.beginTime = shape.convertTime(GamingGlowClock.anchor, from: nil)
            shape.add(animation, forKey: "rainbow")
            gamingLayer = shape
        }
        needsDisplay = true
    }

    /// 塗りつぶし可能な「切り欠き形状」パス（角丸/スクイークルは矩形−くり抜きの even-odd）。
    /// くり抜き側は bounds の外にはみ出ない象限パイ型で構成する（クリップ不要にするため）。
    private func gamingFillPath(in bounds: NSRect) -> CGPath {
        let path = CGMutablePath()
        switch cutoutStyle {
        case .rounded:
            path.addRect(bounds)
            path.addPath(createRoundedQuadrantPath(in: bounds, cornerType: cornerType))
        case .squircle:
            path.addRect(bounds)
            path.addPath(createSquircleCutoutPath(in: bounds, cornerType: cornerType))
        case .polygon:
            path.addPath(createPolygonMaskPath(in: bounds, cornerType: cornerType))
        }
        return path
    }

    /// 角丸くり抜きの象限パイ版。円全体ではなく bounds 内の 1/4 象限のみを閉路にする。
    private func createRoundedQuadrantPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        CornerGeometry.roundedQuadrantPath(in: bounds, radius: radius, cornerType: cornerType)
    }

    /// baseHue（周回上の位置）から1周ぶん巡回する色。ふちのBloomと連続するようにする。
    private func rainbowCGColors(baseHue: Double) -> [CGColor] {
        (0...GamingGlowClock.steps).map { i in
            let hue = (baseHue + Double(i) / Double(GamingGlowClock.steps)).truncatingRemainder(dividingBy: 1.0)
            return NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // ゲーミング時は黒マスクを描かず、虹色レイヤー（gamingLayer）に任せる
        if isGaming { return }

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // 拡張されたウィンドウサイズに対応。元のサイズでコンテンツを描画
        let contentSize = self.contentSize
        let contentBounds = NSRect(x: CornerOverlayConstants.contentSizeOffset, y: CornerOverlayConstants.contentSizeOffset, width: contentSize, height: contentSize)

        // 角マスクを描画（発光はゲーミング時に GamingGlowWindow が別途担当する）
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.setFillColor(color.cgColor)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.0)
        context.setBlendMode(.copy)

        drawCornerMask(in: contentBounds, cornerType: cornerType, context: context)
    }
    
    private func drawCornerMask(in bounds: NSRect, cornerType: CornerType, context: CGContext) {
        switch cutoutStyle {
        case .rounded:
            context.fill(bounds)
            context.setBlendMode(.clear)
            context.addPath(createRoundedCutoutPath(in: bounds, cornerType: cornerType))
            context.fillPath()
            context.setBlendMode(.normal)
        case .squircle:
            context.fill(bounds)
            context.setBlendMode(.clear)
            context.addPath(createSquircleCutoutPath(in: bounds, cornerType: cornerType))
            context.fillPath()
            context.setBlendMode(.normal)
        case .polygon:
            context.addPath(createPolygonMaskPath(in: bounds, cornerType: cornerType))
            context.fillPath()
        }
    }

    /// スーパー楕円（Squircle）の切り欠きパス。内側の角を中心に、iOS風の連続的な曲率で描く。
    /// 曲線はウィンドウ枠の両端（画面のふち上）でちょうど厚み0になるよう、枠いっぱいの
    /// 到達幅で象限パイ型に構成する（端のリップ・内側への突き出しが構造的に出ない）。
    /// ウィンドウ自体は radius より辺方向に長く取ってあり（applyOverlayConfiguration 側）、
    /// 対角の深さが角丸とほぼ揃う。
    private func createSquircleCutoutPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        // キャッシュチェック
        if cachedSquirclePath != nil &&
           cachedSquircleRadius == radius &&
           cachedSquircleSize == contentSize {
            return cachedSquirclePath!
        }

        let path = CornerGeometry.squircleCutoutPath(in: bounds, cornerType: cornerType)

        // キャッシュを更新
        cachedSquirclePath = path
        cachedSquircleRadius = radius
        cachedSquircleSize = contentSize

        return path
    }

    private func createRoundedCutoutPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        CornerGeometry.roundedCutoutPath(in: bounds, radius: radius, cornerType: cornerType)
    }

    private func createPolygonMaskPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        CornerGeometry.polygonMaskPath(in: bounds, radius: radius, cornerType: cornerType)
    }
    
}

enum CornerType {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum CornerCutoutStyle: String, Codable, CaseIterable, Identifiable {
    case rounded
    case squircle
    case polygon

    var id: String { rawValue }

    var localizedDisplayName: String {
        switch self {
        case .rounded:
            return String(localized: "rounded_corner")
        case .squircle:
            return String(localized: "squircle_corner")
        case .polygon:
            return String(localized: "polygon_cutout")
        }
    }
}
