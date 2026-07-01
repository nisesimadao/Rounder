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
    /// レインボーカラーの彩度
    static let rainbowSaturation = 0.9
    /// レインボーカラーの明度
    static let rainbowBrightness = 0.8
    /// ブルームエフェクトの彩度
    static let bloomSaturation = 1.0
    /// ブルームエフェクトの明度
    static let bloomBrightness = 1.0
    /// コンテンツサイズのオフセット
    static let contentSizeOffset: CGFloat = 50
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

// MARK: - Shared Color Cache
/// 色キャッシュを共有するシングルトン クラス
/// 起動時に一度だけ色キャッシュを計算し、すべてのインスタンスで共有する
final class SharedColorCache {
    /// シングルトン インスタンス
    static let shared = SharedColorCache()
    /// キャッシュされた色の配列（init で一度だけ計算し、以後は不変）
    private let cachedColors: [NSColor]

    /// プライベートイニシャライザ。起動時に一度だけレインボーの色を計算する。
    /// 生成後は不変なので、描画のたびにロックを取る必要はない。
    private init() {
        cachedColors = (0..<CornerOverlayConstants.rainbowColorCount).map { i in
            let hue = Double(i) / Double(CornerOverlayConstants.rainbowColorCount)
            return NSColor(
                hue: hue,
                saturation: CornerOverlayConstants.rainbowSaturation,
                brightness: CornerOverlayConstants.rainbowBrightness,
                alpha: 1.0
            )
        }
    }

    /// 指定されたインデックスの色を取得する
    /// - Parameter index: 色のインデックス
    /// - Returns: キャッシュされた色
    func getColor(at index: Int) -> NSColor {
        guard cachedColors.indices.contains(index) else {
            return cachedColors[0]
        }
        return cachedColors[index]
    }

    /// キャッシュされた色の数を取得する
    var count: Int { cachedColors.count }
}

class CornerOverlayWindow: NSWindow {
    private let size: CGFloat
    private var radius: CGFloat
    private var color: NSColor
    private var cutoutStyle: CornerCutoutStyle
    private let cornerType: CornerType

    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }

    init(corner: CGPoint, size: CGFloat, radius: CGFloat, color: NSColor = .black, cutoutStyle: CornerCutoutStyle = .rounded, cornerType: CornerType) {
        self.size = size
        self.radius = radius
        self.color = color
        self.cutoutStyle = cutoutStyle
        self.cornerType = cornerType

        // スーパーゲーミングモードのシャドウが見切れないようにウィンドウサイズを拡張
        let extendedSize = size + 100 // シャドウ用の余白を追加
        let adjustedOrigin = CGPoint(
            x: corner.x - 50,
            y: corner.y - 50
        )
        
        super.init(
            contentRect: NSRect(origin: adjustedOrigin, size: CGSize(width: extendedSize, height: extendedSize)),
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
        self.contentView = contentView
        
        orderFront(nil)
    }
    
    func setGamingMode(_ enabled: Bool, speed: Double, glowIntensity: Double) {
        if let contentView = contentView as? CornerOverlayView {
            contentView.setGamingMode(enabled, speed: speed, glowIntensity: glowIntensity)
        }
    }

    func prepareForClose() {
        if let contentView = contentView as? CornerOverlayView {
            contentView.stopAnimations()
        }
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
    private var isGamingMode: Bool = false
    private var gamingSpeed: Double = PresetManagerConstants.defaultGamingSpeed
    private var glowIntensity: Double = PresetManagerConstants.defaultGlowIntensity
    private var glowTimer: Timer?
    private var glowPhase: Double = 0.0
    
    // Core Animation用のプロパティ
    private var colorAnimationLayer: CALayer?
    private var bloomLayer: CALayer?
    private var animationKey = "hueAnimation"
    
    // バックグラウンドスレッド用のプロパティ
    private var lastColorIndex: Int = 0
    
    init(radius: CGFloat, color: NSColor, cutoutStyle: CornerCutoutStyle, contentSize: CGFloat, cornerType: CornerType) {
        self.radius = radius
        self.color = color
        self.cutoutStyle = cutoutStyle
        self.contentSize = contentSize
        self.cornerType = cornerType
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setGamingMode(_ enabled: Bool, speed: Double, glowIntensity: Double) {
        isGamingMode = enabled
        gamingSpeed = speed
        self.glowIntensity = glowIntensity
        
        if isGamingMode {
            setupCoreAnimation()
            startGlowAnimation()
        } else {
            stopGlowAnimation()
            removeCoreAnimation()
            // 通常モードの描画へ戻すためここで再描画する
            needsDisplay = true
        }

        // 設定変更時に色キャッシュは共有キャッシュを使用するため再計算不要
    }
    
    private func setupCoreAnimation() {
        guard colorAnimationLayer == nil else { return }
        
        // 色変化用のレイヤーをセットアップ
        colorAnimationLayer = CALayer()
        colorAnimationLayer?.frame = bounds
        colorAnimationLayer?.backgroundColor = NSColor.red.cgColor
        
        // Bloom効果用のレイヤーをセットアップ
        bloomLayer = CALayer()
        bloomLayer?.frame = CGRect(x: 0, y: 0, width: CornerOverlayConstants.bloomLayerSize, height: CornerOverlayConstants.bloomLayerSize)
        bloomLayer?.backgroundColor = NSColor.red.cgColor
        bloomLayer?.shadowColor = NSColor.red.cgColor
        bloomLayer?.shadowRadius = CornerOverlayConstants.bloomShadowRadius
        bloomLayer?.shadowOpacity = CornerOverlayConstants.bloomShadowOpacity
        bloomLayer?.masksToBounds = false
        
        layer?.addSublayer(colorAnimationLayer!)
        layer?.addSublayer(bloomLayer!)
        
        startColorAnimation()
    }
    
    private func removeCoreAnimation() {
        colorAnimationLayer?.removeFromSuperlayer()
        bloomLayer?.removeFromSuperlayer()
        colorAnimationLayer = nil
        bloomLayer = nil
    }
    
    private func startColorAnimation() {
        guard let layer = colorAnimationLayer else { return }
        
        // キーフレームアニメーションで色を滑らかに変化
        let animation = CAKeyframeAnimation(keyPath: "backgroundColor")
        animation.duration = CornerOverlayConstants.baseColorAnimationDuration / gamingSpeed
        animation.repeatCount = .infinity
        animation.calculationMode = .linear
        
        // HSB色空間で色を計算
        var colors: [CGColor] = []
        var bloomColors: [CGColor] = []
        
        for i in 0..<CornerOverlayConstants.rainbowColorCount {
            let hue = Double(i) / Double(CornerOverlayConstants.rainbowColorCount)
            let color = NSColor(hue: hue, saturation: CornerOverlayConstants.rainbowSaturation, brightness: CornerOverlayConstants.rainbowBrightness, alpha: 1.0)
            colors.append(color.cgColor)
            bloomColors.append(NSColor(hue: hue, saturation: CornerOverlayConstants.bloomSaturation, brightness: CornerOverlayConstants.bloomBrightness, alpha: 1.0).cgColor)
        }
        
        animation.values = colors
        layer.add(animation, forKey: animationKey)
        
        // Bloomレイヤーの色も更新
        if let bloomLayer = bloomLayer {
            let bloomAnimation = CAKeyframeAnimation(keyPath: "backgroundColor")
            bloomAnimation.duration = 3.0 / gamingSpeed
            bloomAnimation.repeatCount = .infinity
            bloomAnimation.values = bloomColors
            bloomLayer.add(bloomAnimation, forKey: "bloomColor")
            
            // Bloomレイヤーの位置を更新
            updateBloomPosition()
        }
    }
    
    private func updateBloomPosition() {
        guard let bloomLayer = bloomLayer else { return }
        
        let contentBounds = NSRect(x: 50, y: 50, width: contentSize, height: contentSize)
        let bloomRect = getBloomPosition(in: contentBounds, cornerType: cornerType, size: 6.0)
        
        // レイヤーの位置を更新
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bloomLayer.frame = bloomRect
        CATransaction.commit()
    }
    
    private func startGlowAnimation() {
        stopGlowAnimation()

        // メニューを開いたりウィンドウをトラッキング中でも止まらないよう .common モードで登録する。
        // scheduledTimer だと .default モードのみに入り、トラッキング中に色更新が固まってしまう。
        let timer = Timer(timeInterval: CornerOverlayConstants.gamingUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateGlowPhase()
        }
        RunLoop.main.add(timer, forMode: .common)
        glowTimer = timer
    }
    
    private func updateGlowPhase() {
        // 軽量な計算のみUIスレッドで実行
        glowPhase += CornerOverlayConstants.glowPhaseIncrement * gamingSpeed
        if glowPhase > CornerOverlayConstants.twoPi {
            glowPhase -= CornerOverlayConstants.twoPi
        }
        
        // 色インデックスを更新
        let colorIndex = Int((glowPhase / CornerOverlayConstants.twoPi) * Double(CornerOverlayConstants.rainbowColorCount))
        if colorIndex != lastColorIndex {
            lastColorIndex = colorIndex
            needsDisplay = true
        }
    }
    
    private func stopGlowAnimation() {
        // すべてのタイマーを停止
        glowTimer?.invalidate()
        glowTimer = nil

        glowPhase = 0.0
        lastColorIndex = 0
        // ここでは再描画を要求しない（deinit 経由でも呼ばれるため）。
        // 通常モードへ戻す再描画は setGamingMode(false) 側で行う。
    }

    func stopAnimations() {
        stopGlowAnimation()
        removeCoreAnimation()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 拡張されたウィンドウサイズに対応。元のサイズでコンテンツを描画
        let contentSize = self.contentSize
        let contentBounds = NSRect(x: CornerOverlayConstants.contentSizeOffset, y: CornerOverlayConstants.contentSizeOffset, width: contentSize, height: contentSize)

        if isGamingMode {
            // ゲーミングモード：レインボー色変化効果（パフォーマンス最適化）
            let colorIndex = min(Int((glowPhase / CornerOverlayConstants.twoPi) * Double(CornerOverlayConstants.rainbowColorCount)), SharedColorCache.shared.count - 1)
            let currentColor = SharedColorCache.shared.getColor(at: colorIndex)
            
            context.setFillColor(currentColor.cgColor)
            drawCornerMask(in: contentBounds, cornerType: cornerType, context: context)
            
            // Bloom効果：小さな正方形に大きなシャドウを適用
            context.setBlendMode(.normal)
            context.setFillColor(currentColor.cgColor)
            context.setShadow(
                offset: .zero,
                blur: 50.0 + glowIntensity * 40.0,
                color: currentColor.cgColor
            )
            
            // 切り欠きの根元に小さな正方形を配置
            let smallSquareSize: CGFloat = 6.0
            let bloomRect = getBloomPosition(in: contentBounds, cornerType: cornerType, size: smallSquareSize)
            context.fill(bloomRect)
            
            // 追加のbloomレイヤー
            context.setShadow(
                offset: .zero,
                blur: 80.0 + glowIntensity * 60.0,
                color: currentColor.cgColor
            )
            context.fill(bloomRect)
            
                        
        } else {
            // 通常モード
            context.setShouldAntialias(true)
            context.setAllowsAntialiasing(true)
            context.setFillColor(color.cgColor)
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(1.0)
            
            // 効率的な描画モード
            context.setBlendMode(.copy)
            
            drawCornerMask(in: contentBounds, cornerType: cornerType, context: context)
        }
    }
    
    private func drawCornerMask(in bounds: NSRect, cornerType: CornerType, context: CGContext) {
        switch cutoutStyle {
        case .rounded:
            context.fill(bounds)
            context.setBlendMode(.clear)
            context.addPath(createRoundedCutoutPath(in: bounds, cornerType: cornerType))
            context.fillPath()
            context.setBlendMode(.normal)
        case .polygon:
            context.addPath(createPolygonMaskPath(in: bounds, cornerType: cornerType))
            context.fillPath()
        }
    }

    private func createRoundedCutoutPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        let path = CGMutablePath()
        let circleRadius = radius
        
        switch cornerType {
        case .topLeft:
            path.addEllipse(in: CGRect(
                x: bounds.maxX - circleRadius,
                y: bounds.maxY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
        case .topRight:
            path.addEllipse(in: CGRect(
                x: bounds.minX - circleRadius,
                y: bounds.maxY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
        case .bottomLeft:
            path.addEllipse(in: CGRect(
                x: bounds.maxX - circleRadius,
                y: bounds.minY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
        case .bottomRight:
            path.addEllipse(in: CGRect(
                x: bounds.minX - circleRadius,
                y: bounds.minY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
        }
        
        return path
    }

    private func createPolygonMaskPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        let path = CGMutablePath()
        let inset = min(radius, min(bounds.width, bounds.height))
        
        guard inset > 0 else {
            return path
        }
        
        let points: [CGPoint]
        switch cornerType {
        case .topLeft:
            points = [
                CGPoint(x: bounds.minX, y: bounds.minY),
                CGPoint(x: bounds.minX + inset, y: bounds.minY),
                CGPoint(x: bounds.minX, y: bounds.minY + inset)
            ]
        case .topRight:
            points = [
                CGPoint(x: bounds.maxX, y: bounds.minY),
                CGPoint(x: bounds.maxX - inset, y: bounds.minY),
                CGPoint(x: bounds.maxX, y: bounds.minY + inset)
            ]
        case .bottomLeft:
            points = [
                CGPoint(x: bounds.minX, y: bounds.maxY),
                CGPoint(x: bounds.minX + inset, y: bounds.maxY),
                CGPoint(x: bounds.minX, y: bounds.maxY - inset)
            ]
        case .bottomRight:
            points = [
                CGPoint(x: bounds.maxX, y: bounds.maxY),
                CGPoint(x: bounds.maxX - inset, y: bounds.maxY),
                CGPoint(x: bounds.maxX, y: bounds.maxY - inset)
            ]
        }
        
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }
    
    private func getBloomPosition(in bounds: NSRect, cornerType: CornerType, size: CGFloat) -> NSRect {
        switch cornerType {
        case .topLeft:
            // 左上隅：さらに画面の外側に配置
            return NSRect(
                x: bounds.minX - size/2,
                y: bounds.minY - size/2,
                width: size,
                height: size
            )
            
        case .topRight:
            // 右上隅：さらに画面の外側に配置
            return NSRect(
                x: bounds.maxX + size/2,
                y: bounds.minY - size/2,
                width: size,
                height: size
            )
            
        case .bottomLeft:
            // 左下隅：さらに画面の外側に配置
            return NSRect(
                x: bounds.minX - size/2,
                y: bounds.maxY + size/2,
                width: size,
                height: size
            )
            
        case .bottomRight:
            // 右下隅：さらに画面の外側に配置
            return NSRect(
                x: bounds.maxX + size/2,
                y: bounds.maxY + size/2,
                width: size,
                height: size
            )
        }
    }
    
    deinit {
        stopAnimations()
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
    case polygon

    var id: String { rawValue }

    var localizedDisplayName: String {
        switch self {
        case .rounded:
            return String(localized: "rounded_corner")
        case .polygon:
            return String(localized: "polygon_cutout")
        }
    }
}
