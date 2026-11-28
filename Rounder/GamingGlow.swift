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

/// オーバーレイ専用の「常時表示 Space」を作り、そこへ窓を移す（SkyLight の私有API）。
/// 通常の Space に属した窓は、Space 切替のスライドアニメーション中に出ていく側の
/// レイヤーと一緒に流れてしまい、入ってくる側には切り欠きが無い片側状態になる。
/// 独自に作った Space は常に画面へ重ねて表示され、遷移アニメーションに参加しない
/// ため、切り欠き・発光が常に固定表示される（JankyBorders / yabai と同じ手法）。
/// 私有APIのため dlsym で解決し、存在しない環境では静かに何もしない
/// （その場合は従来どおり canJoinAllSpaces の挙動になるだけ）。
enum OverlaySpace {
    private typealias MainConnectionFunc = @convention(c) () -> Int32
    private typealias SpaceCreateFunc = @convention(c) (Int32, Int32, CFDictionary?) -> UInt64
    private typealias SpaceSetAbsoluteLevelFunc = @convention(c) (Int32, UInt64, Int32) -> Void
    private typealias ShowSpacesFunc = @convention(c) (Int32, CFArray) -> Void
    private typealias SpaceAddWindowsFunc = @convention(c) (Int32, UInt64, CFArray, Int32) -> Void

    private static let functions: (
        main: MainConnectionFunc,
        create: SpaceCreateFunc,
        setLevel: SpaceSetAbsoluteLevelFunc,
        show: ShowSpacesFunc,
        addWindows: SpaceAddWindowsFunc
    )? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let mainSym = dlsym(handle, "SLSMainConnectionID"),
              let createSym = dlsym(handle, "SLSSpaceCreate"),
              let levelSym = dlsym(handle, "SLSSpaceSetAbsoluteLevel"),
              let showSym = dlsym(handle, "SLSShowSpaces"),
              let addSym = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces") else { return nil }
        return (unsafeBitCast(mainSym, to: MainConnectionFunc.self),
                unsafeBitCast(createSym, to: SpaceCreateFunc.self),
                unsafeBitCast(levelSym, to: SpaceSetAbsoluteLevelFunc.self),
                unsafeBitCast(showSym, to: ShowSpacesFunc.self),
                unsafeBitCast(addSym, to: SpaceAddWindowsFunc.self))
    }()

    /// 一度だけ作るオーバーレイ専用 Space の ID（0 = 未作成/失敗）
    private static var spaceID: UInt64 = 0

    /// Move an overlay back to the active ordinary Space without replacing it.
    /// The same WindowServer operation removes its previous overlay-Space membership.
    @discardableResult
    static func attachToCurrentDesktop(_ windows: [NSWindow], displayID: CGDirectDisplayID) -> Bool {
        typealias CopySpaces = @convention(c) (Int32) -> Unmanaged<CFArray>?
        guard let functions,
              let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let symbol = dlsym(handle, "SLSCopyManagedDisplaySpaces"),
              let displays = unsafeBitCast(symbol, to: CopySpaces.self)(functions.main())?.takeRetainedValue() as? [[String: Any]],
              let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else { return false }
        let identifier = CFUUIDCreateString(nil, uuid) as String
        let isPrimary = CGMainDisplayID() == displayID
        guard let display = displays.first(where: {
            let name = $0["Display Identifier"] as? String
            return name == identifier || (isPrimary && name == "Main")
        }), let current = display["Current Space"] as? [String: Any],
            let target = current["ManagedSpaceID"] as? NSNumber else { return false }
        let ids = windows.filter { $0.windowNumber > 0 }.map { NSNumber(value: $0.windowNumber) }
        guard !ids.isEmpty else { return true }
        functions.addWindows(functions.main(), target.uint64Value, ids as CFArray, 0x7)
        typealias CopyWindowSpaces = @convention(c) (Int32, Int32, CFArray) -> Unmanaged<CFArray>?
        guard let copySymbol = dlsym(handle, "SLSCopySpacesForWindows"),
              let actual = unsafeBitCast(copySymbol, to: CopyWindowSpaces.self)(functions.main(), 7, ids as CFArray)?.takeRetainedValue() as? [NSNumber] else { return false }
        return Set(actual.map(\.uint64Value)) == [target.uint64Value]
    }

    /// 窓をオーバーレイ専用 Space へ移す。窓を作り直すたびに呼び直すこと。
    static func pin(_ windows: [NSWindow]) {
        guard let functions else { return }
        let cid = functions.main()

        if spaceID == 0 {
            spaceID = functions.create(cid, 1, nil)
            guard spaceID != 0 else { return }
            functions.setLevel(cid, spaceID, 0)
            functions.show(cid, [NSNumber(value: spaceID)] as CFArray)
        }

        let windowIDs = windows.compactMap { $0.windowNumber > 0 ? NSNumber(value: $0.windowNumber) : nil }
        guard !windowIDs.isEmpty else { return }
        functions.addWindows(cid, spaceID, windowIDs as CFArray, 0x7)
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

    private static var gradientFrameCache: [Double: [[CGColor]]] = [:]

    static func rainbowColor(baseHue: Double, phase: Double) -> CGColor {
        let hue = (baseHue + phase).truncatingRemainder(dividingBy: 1.0)
        return NSColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor
    }

    static func cornerColors(baseHue: Double) -> [CGColor] {
        (0...steps).map { rainbowColor(baseHue: baseHue, phase: Double($0) / Double(steps)) }
    }

    static func gradientColors(baseHue: Double, phase: Double) -> [CGColor] {
        (0...6).map { rainbowColor(baseHue: baseHue + Double($0) / 6 * 0.25, phase: phase) }
    }

    /// Keep white menu text at a contrast ratio of at least 4.5:1.
    /// Scale linear RGB together so bright yellow/green retain their hue.
    static func menuBarColor(_ color: CGColor) -> CGColor {
        guard let rgb = NSColor(cgColor: color)?.usingColorSpace(.sRGB) else { return color }
        func linear(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        func encoded(_ value: CGFloat) -> CGFloat {
            value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
        }
        let red = linear(rgb.redComponent), green = linear(rgb.greenComponent), blue = linear(rgb.blueComponent)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        guard luminance > 0.18 else { return color }
        let scale = 0.18 / luminance
        return NSColor(srgbRed: encoded(red * scale), green: encoded(green * scale),
                       blue: encoded(blue * scale), alpha: rgb.alphaComponent).cgColor
    }

    /// Constant-color ends meet the solid corner masks without a visible seam.
    static func topGradientLocations(width: CGFloat, cornerSize: CGFloat) -> [NSNumber] {
        let inset = width > 0 ? min(max(cornerSize / width, 0), 0.49) : 0
        return (0...6).map { NSNumber(value: Double(inset) + Double($0) / 6 * Double(1 - 2 * inset)) }
    }

    static func addRainbowAnimation(to layer: CAGradientLayer, baseHue: Double, speed: Double, menuBar: Bool = false) {
        let frames: [[CGColor]]
        if let cached = gradientFrameCache[baseHue] {
            frames = cached
        } else {
            frames = (0...steps).map { gradientColors(baseHue: baseHue, phase: Double($0) / Double(steps)) }
            gradientFrameCache[baseHue] = frames
        }
        let displayFrames = menuBar ? frames.map { colors in colors.map { menuBarColor($0) } } : frames
        layer.colors = displayFrames.first
        let animation = CAKeyframeAnimation(keyPath: "colors")
        animation.values = displayFrames
        animation.duration = CornerOverlayConstants.baseColorAnimationDuration / max(0.1, speed)
        animation.repeatCount = .infinity
        animation.calculationMode = .linear
        animation.isRemovedOnCompletion = false
        animation.beginTime = layer.convertTime(anchor, from: nil)
        layer.add(animation, forKey: "rainbow")
    }

    /// ふちから内側へ届く光の幅。プロファイル基準（24px）× 広さ設定。
    static func reach(bloomWidth: Double) -> CGFloat {
        max(5, 24 * CGFloat(bloomWidth))
    }
}

/// 画面の1辺ぶんのゲーミング発光バンドウィンドウ（1スクリーンにつき4枚）。
final class GamingGlowWindow: NSWindow {
    var overlayDisplayID: CGDirectDisplayID?
    private let edge: ScreenEdge
    var isTopEdge: Bool { edge == .top }
    private let reach: CGFloat
    private var placementTargetFrame: NSRect?
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Overlay placement is already computed from the physical display bounds.
    /// AppKit otherwise moves windows below the menu bar at levels below Dock,
    /// adding a second top inset even when menu-bar exclusion is disabled.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(screenFrame: NSRect, edge: ScreenEdge, speed: Double, glowIntensity: Double, bloomWidth: Double, cornerSize: CGFloat = 0) {
        let reach = GamingGlowClock.reach(bloomWidth: bloomWidth)
        self.edge = edge
        self.reach = reach
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
        contentView = GamingGlowEdgeView(size: bandFrame.size, edge: edge, speed: speed, glowIntensity: glowIntensity, cornerSize: cornerSize)
        // アプリが非アクティブ（常時）でも確実に前面へ出す
        orderFrontRegardless()
    }

    func updatePlacement(in screenFrame: NSRect, animated: Bool = false) {
        let newFrame: NSRect
        switch edge {
        case .top: newFrame = NSRect(x: screenFrame.minX, y: screenFrame.maxY - reach, width: screenFrame.width, height: reach)
        case .bottom: newFrame = NSRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: reach)
        case .left: newFrame = NSRect(x: screenFrame.minX, y: screenFrame.minY, width: reach, height: screenFrame.height)
        case .right: newFrame = NSRect(x: screenFrame.maxX - reach, y: screenFrame.minY, width: reach, height: screenFrame.height)
        }
        guard newFrame != placementTargetFrame else { return }
        placementTargetFrame = newFrame
        if animated && collectionBehavior.contains(.stationary) && alphaValue > 0 &&
            !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                animator().setFrame(newFrame, display: false)
            }
        } else {
            setFrame(newFrame, display: false)
        }
        contentView?.needsLayout = true
    }

    func updateCornerSize(_ cornerSize: CGFloat) {
        (contentView as? GamingGlowEdgeView)?.updateCornerSize(cornerSize)
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
    private var cornerSize: CGFloat
    private var hueLayer: CAGradientLayer?

    init(size: CGSize, edge: ScreenEdge, speed: Double, glowIntensity: Double, cornerSize: CGFloat = 0) {
        self.edge = edge
        self.speed = max(0.1, speed)
        self.glowIntensity = glowIntensity
        self.cornerSize = cornerSize
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        autoresizingMask = [.width, .height]
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

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        hueLayer?.frame = bounds
        hueLayer?.mask?.frame = bounds
        if edge == .top {
            hueLayer?.locations = GamingGlowClock.topGradientLocations(width: bounds.width, cornerSize: cornerSize)
        }
        CATransaction.commit()
    }

    private func setupLayer(size: CGSize) {
        let spec = self.spec

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
        if edge == .top {
            hueLayer.locations = GamingGlowClock.topGradientLocations(width: size.width, cornerSize: cornerSize)
        }

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

        GamingGlowClock.addRainbowAnimation(to: hueLayer, baseHue: spec.base, speed: speed)
    }

    func updateCornerSize(_ cornerSize: CGFloat) {
        self.cornerSize = cornerSize
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    func stop() {
        hueLayer?.removeAllAnimations()
    }

    deinit {
        stop()
    }
}
