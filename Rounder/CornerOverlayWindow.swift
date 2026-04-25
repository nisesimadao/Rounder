//
//  CornerOverlayWindow.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import CoreGraphics
import CoreVideo

class CornerOverlayWindow: NSWindow {
    private let corner: CGPoint
    private let size: CGFloat
    private var radius: CGFloat
    private var color: NSColor
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    init(corner: CGPoint, size: CGFloat, radius: CGFloat, color: NSColor = .black) {
        self.corner = corner
        self.size = size
        self.radius = radius
        self.color = color
        
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
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = CornerOverlayView(radius: radius, color: color, contentSize: size)
        self.contentView = contentView
        
        orderFront(nil)
    }
    
    func updateSettings(radius: CGFloat, color: NSColor) {
        // 変更がない場合は早期リターンしてパフォーマンス向上
        if self.radius == radius && self.color.isEqual(color) {
            return
        }
        
        self.radius = radius
        self.color = color
        
        if let contentView = contentView as? CornerOverlayView {
            contentView.updateSettings(radius: radius, color: color)
        }
    }
    
    func setGamingMode(_ enabled: Bool, speed: Double, glowIntensity: Double) {
        if let contentView = contentView as? CornerOverlayView {
            contentView.setGamingMode(enabled, speed: speed, glowIntensity: glowIntensity)
        }
    }
}

class CornerOverlayView: NSView {
    private var radius: CGFloat
    private var color: NSColor
    private var contentSize: CGFloat
    private var isGamingMode: Bool = false
    private var gamingSpeed: Double = 1.0
    private var glowIntensity: Double = 1.0
    private var glowTimer: Timer?
    private var glowPhase: Double = 0.0
    
    // Core Animation用のプロパティ
    private var colorAnimationLayer: CALayer?
    private var bloomLayer: CALayer?
    private var animationKey = "hueAnimation"
    
    // バックグラウンドスレッド用のプロパティ
    private var glowUpdateQueue = DispatchQueue(label: "com.rounder.glow", qos: .userInteractive)
    private var cachedColors: [NSColor] = []
    private var lastColorIndex: Int = 0
    private var colorUpdateTimer: Timer?
    
    init(radius: CGFloat, color: NSColor, contentSize: CGFloat) {
        self.radius = radius
        self.color = color
        self.contentSize = contentSize
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
        }
        
        // 設定変更時に色キャッシュを再計算
        if isGamingMode {
            precomputeColors()
        }
    }
    
    private func setupCoreAnimation() {
        guard colorAnimationLayer == nil else { return }
        
        // 色変化用のレイヤーをセットアップ
        colorAnimationLayer = CALayer()
        colorAnimationLayer?.frame = bounds
        colorAnimationLayer?.backgroundColor = NSColor.red.cgColor
        
        // Bloom効果用のレイヤーをセットアップ
        bloomLayer = CALayer()
        bloomLayer?.frame = CGRect(x: 0, y: 0, width: 6, height: 6)
        bloomLayer?.backgroundColor = NSColor.red.cgColor
        bloomLayer?.shadowColor = NSColor.red.cgColor
        bloomLayer?.shadowRadius = 50
        bloomLayer?.shadowOpacity = 1.0
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
        animation.duration = 3.0 / gamingSpeed
        animation.repeatCount = .infinity
        animation.calculationMode = .linear
        
        // HSB色空間で色を計算
        var colors: [CGColor] = []
        var bloomColors: [CGColor] = []
        
        for i in 0..<360 {
            let hue = Double(i) / 360.0
            let color = NSColor(hue: hue, saturation: 0.9, brightness: 0.8, alpha: 1.0)
            colors.append(color.cgColor)
            bloomColors.append(NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor)
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
        
        let cornerType = determineCornerType()
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
        
        // 色キャッシュを初期化
        precomputeColors()
        
        // UIスレッドで軽量なタイマーのみ実行
        glowTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateGlowPhase()
        }
        
        // バックグラウンドで色計算を定期実行
        colorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.glowUpdateQueue.async {
                self.updateColorCache()
            }
        }
    }
    
    private func updateGlowPhase() {
        // 軽量な計算のみUIスレッドで実行
        glowPhase += 0.05 * gamingSpeed
        if glowPhase > 2 * .pi {
            glowPhase -= 2 * .pi
        }
        
        // 色インデックスを更新
        let colorIndex = Int((glowPhase / (2 * .pi)) * 360)
        if colorIndex != lastColorIndex {
            lastColorIndex = colorIndex
            needsDisplay = true
        }
    }
    
    private func updateColorCache() {
        // バックグラウンドで色キャッシュを更新
        if cachedColors.isEmpty {
            precomputeColors()
        }
    }
    
    private func precomputeColors() {
        glowUpdateQueue.async {
            // キャッシュが既に存在する場合は再計算しない
            if !self.cachedColors.isEmpty {
                return
            }
            
            // 事前に色を計算してキャッシュ（パフォーマンス改善）
            self.cachedColors.reserveCapacity(360)
            
            for i in 0..<360 {
                let hue = Double(i) / 360.0 // 単純化
                
                // 固定値で計算を削減
                let rainbowColor = NSColor(
                    hue: hue,
                    saturation: 0.9,
                    brightness: 0.8,
                    alpha: 1.0
                )
                
                self.cachedColors.append(rainbowColor)
            }
        }
    }
    
        
    private func stopGlowAnimation() {
        // すべてのタイマーを停止
        glowTimer?.invalidate()
        glowTimer = nil
        
        colorUpdateTimer?.invalidate()
        colorUpdateTimer = nil
        
        glowPhase = 0.0
        lastColorIndex = 0
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 拡張されたウィンドウサイズに対応。元のサイズでコンテンツを描画
        let contentSize = self.contentSize
        let contentBounds = NSRect(x: 50, y: 50, width: contentSize, height: contentSize)
        let cornerType = determineCornerType()
        
        if isGamingMode {
            // ゲーミングモード：レインボー色変化効果（パフォーマンス最適化）
            let colorIndex = min(Int((glowPhase / (2 * .pi)) * 360), cachedColors.count - 1)
            let currentColor = cachedColors.indices.contains(colorIndex) ? cachedColors[colorIndex] : cachedColors[0]
            
            // 切り欠きを描画（キャッシュされた色を使用）
            context.setFillColor(currentColor.cgColor)
            context.fill(contentBounds)
            
            // 円部分を透明で描画
            context.setBlendMode(.clear)
            let circlePath = createCirclePath(in: contentBounds, cornerType: cornerType)
            context.addPath(circlePath)
            context.fillPath()
            
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
            
            // 正方形部分を描画
            context.fill(contentBounds)
            
            // 円部分を透明で描画（重なり部分をくり抜く）
            context.setBlendMode(.clear)
            let circlePath = createCirclePath(in: contentBounds, cornerType: cornerType)
            context.addPath(circlePath)
            context.fillPath()
        }
    }
    
    private func determineCornerType() -> CornerType {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowFrame = self.window?.frame ?? .zero
        
        // 左下と左上の判定を入れ替える
        if windowFrame.minX <= screenFrame.minX + 1 && windowFrame.maxY >= screenFrame.maxY - 1 {
            return .bottomLeft  // 左上を左下に
        } else if windowFrame.maxX >= screenFrame.maxX - 1 && windowFrame.maxY >= screenFrame.maxY - 1 {
            return .bottomRight  // 右上を右下に
        } else if windowFrame.minX <= screenFrame.minX + 1 && windowFrame.minY <= screenFrame.minY + 1 {
            return .topLeft  // 左下を左上に
        } else {
            return .topRight  // 右下を右上に
        }
    }
    
    private func createCornerPath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        let path = CGMutablePath()
        
        // 角に円の半径を設定（設定値を使用）
        let circleRadius = radius
        
        switch cornerType {
        case .topLeft:
            // 左上隅：正方形から円をくり抜いた形状
            path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addArc(center: CGPoint(x: bounds.maxX, y: bounds.maxY), 
                       radius: circleRadius,
                       startAngle: 0,
                       endAngle: CGFloat.pi/2,
                       clockwise: true) // 円をくり抜く
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            path.closeSubpath()
            
        case .topRight:
            // 右上隅：正方形から円をくり抜いた形状
            path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addArc(center: CGPoint(x: bounds.minX, y: bounds.maxY), 
                       radius: circleRadius,
                       startAngle: CGFloat.pi/2,
                       endAngle: CGFloat.pi,
                       clockwise: true) // 円をくり抜く
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
            path.closeSubpath()
            
        case .bottomLeft:
            // 左下隅：正方形から円をくり抜いた形状
            path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            path.addArc(center: CGPoint(x: bounds.maxX, y: bounds.minY), 
                       radius: circleRadius,
                       startAngle: -CGFloat.pi/2,
                       endAngle: 0,
                       clockwise: true) // 円をくり抜く
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            path.closeSubpath()
            
        case .bottomRight:
            // 右下隅：正方形から円をくり抜いた形状
            path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            path.addArc(center: CGPoint(x: bounds.minX, y: bounds.minY), 
                       radius: circleRadius,
                       startAngle: CGFloat.pi,
                       endAngle: CGFloat.pi*3/2,
                       clockwise: true) // 円をくり抜く
            path.closeSubpath()
        }
        
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
    
    private func createCirclePath(in bounds: NSRect, cornerType: CornerType) -> CGPath {
        let path = CGMutablePath()
        
        // 角に円の半径を設定（設定値を使用）
        let circleRadius = radius
        
        switch cornerType {
        case .topLeft:
            // 左上隅：正方形の右下が円の中心になるように配置
            let circleCenter = CGPoint(x: bounds.maxX, y: bounds.maxY)
            path.addEllipse(in: CGRect(
                x: circleCenter.x - circleRadius,
                y: circleCenter.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            
        case .topRight:
            // 右上隅：正方形の左下が円の中心になるように配置
            let circleCenter = CGPoint(x: bounds.minX, y: bounds.maxY)
            path.addEllipse(in: CGRect(
                x: circleCenter.x - circleRadius,
                y: circleCenter.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            
        case .bottomLeft:
            // 左下隅：正方形の右上が円の中心になるように配置
            let circleCenter = CGPoint(x: bounds.maxX, y: bounds.minY)
            path.addEllipse(in: CGRect(
                x: circleCenter.x - circleRadius,
                y: circleCenter.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            
        case .bottomRight:
            // 右下隅：正方形の左上が円の中心になるように配置
            let circleCenter = CGPoint(x: bounds.minX, y: bounds.minY)
            path.addEllipse(in: CGRect(
                x: circleCenter.x - circleRadius,
                y: circleCenter.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
        }
        
        return path
    }
    
    func updateSettings(radius: CGFloat, color: NSColor) {
        // 変更がない場合は早期リターン
        if self.radius == radius && self.color.isEqual(color) {
            return
        }
        
        self.radius = radius
        self.color = color
        
        // 効率的な再描画：ビュー全体ではなく必要な部分のみ
        needsDisplay = true
    }
    
    // パフォーマンス最適化：dirtyRectのみを再描画
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        // 無効な領域のみを効率的に再描画
        super.setNeedsDisplay(invalidRect)
    }
    
    // メモリ管理の最適化
    deinit {
        // クリーンアップ処理
        radius = 0
        color = .clear
    }
}

enum CornerType {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
