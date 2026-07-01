//
//  GamingGlow.swift
//  Rounder
//
//  スーパーゲーミングモードで、画面の四隅だけでなく「ふち（側面）」全体を光らせる。
//  各辺に薄いオーバーレイウィンドウを置き、画面の外側にライトがあるように内側へブルームさせる。
//

import Cocoa

enum ScreenEdge {
    case top, bottom, left, right
}

/// 画面の1辺に沿って光るオーバーレイウィンドウ（ゲーミングモード専用）。
final class EdgeOverlayWindow: NSWindow {
    /// 画面内側へ光が届く深さ（pt）
    static let glowDepth: CGFloat = 160
    /// 画面外側の余白（シャドウ源を置く領域）
    static let overhang: CGFloat = 60

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(edge: ScreenEdge, screenFrame: NSRect, speed: Double, glowIntensity: Double) {
        let d = EdgeOverlayWindow.glowDepth
        let o = EdgeOverlayWindow.overhang

        let frame: NSRect
        switch edge {
        case .top:
            frame = NSRect(x: screenFrame.minX, y: screenFrame.maxY - d, width: screenFrame.width, height: d + o)
        case .bottom:
            frame = NSRect(x: screenFrame.minX, y: screenFrame.minY - o, width: screenFrame.width, height: d + o)
        case .left:
            frame = NSRect(x: screenFrame.minX - o, y: screenFrame.minY, width: d + o, height: screenFrame.height)
        case .right:
            frame = NSRect(x: screenFrame.maxX - d, y: screenFrame.minY, width: d + o, height: screenFrame.height)
        }

        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)

        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        contentView = EdgeOverlayView(edge: edge, glowDepth: d, overhang: o, glowIntensity: glowIntensity, speed: speed)
        orderFront(nil)
    }

    func prepareForClose() {
        (contentView as? EdgeOverlayView)?.stopAnimation()
    }
}

final class EdgeOverlayView: NSView {
    private let edge: ScreenEdge
    private let glowDepth: CGFloat
    private let overhang: CGFloat
    private let glowIntensity: Double
    private let speed: Double

    private var glowPhase: Double = 0.0
    private var lastColorIndex: Int = 0
    private var timer: Timer?

    /// 光源となる細いバーの太さ
    private let barThickness: CGFloat = 4

    init(edge: ScreenEdge, glowDepth: CGFloat, overhang: CGFloat, glowIntensity: Double, speed: Double) {
        self.edge = edge
        self.glowDepth = glowDepth
        self.overhang = overhang
        self.glowIntensity = glowIntensity
        self.speed = speed
        super.init(frame: .zero)
        startAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        stopAnimation()
        let t = Timer(timeInterval: CornerOverlayConstants.gamingUpdateInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopAnimation() {
        timer?.invalidate()
        timer = nil
        glowPhase = 0.0
        lastColorIndex = 0
    }

    private func tick() {
        glowPhase += CornerOverlayConstants.glowPhaseIncrement * speed
        if glowPhase > CornerOverlayConstants.twoPi {
            glowPhase -= CornerOverlayConstants.twoPi
        }
        let idx = Int((glowPhase / CornerOverlayConstants.twoPi) * Double(CornerOverlayConstants.rainbowColorCount))
        if idx != lastColorIndex {
            lastColorIndex = idx
            needsDisplay = true
        }
    }

    /// 画面のふちに沿った、光源となる細いバーの矩形（ウィンドウローカル座標）
    private func barRect() -> NSRect {
        let b = bounds
        let t = barThickness
        switch edge {
        case .top:    return NSRect(x: b.minX, y: glowDepth - t / 2, width: b.width, height: t)
        case .bottom: return NSRect(x: b.minX, y: overhang - t / 2, width: b.width, height: t)
        case .left:   return NSRect(x: overhang - t / 2, y: b.minY, width: t, height: b.height)
        case .right:  return NSRect(x: glowDepth - t / 2, y: b.minY, width: t, height: b.height)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let idx = min(
            Int((glowPhase / CornerOverlayConstants.twoPi) * Double(CornerOverlayConstants.rainbowColorCount)),
            CornerOverlayConstants.rainbowColorCount - 1
        )
        let color = SharedColorCache.shared.getColor(at: idx).cgColor
        let bar = barRect()

        // 角のブルームと同じ強さで、内側へ光をにじませる（2段のシャドウ）
        ctx.setBlendMode(.normal)
        ctx.setFillColor(color)
        ctx.setShadow(offset: .zero, blur: 50.0 + CGFloat(glowIntensity) * 40.0, color: color)
        ctx.fill(bar)
        ctx.setShadow(offset: .zero, blur: 80.0 + CGFloat(glowIntensity) * 60.0, color: color)
        ctx.fill(bar)
    }

    deinit {
        stopAnimation()
    }
}
