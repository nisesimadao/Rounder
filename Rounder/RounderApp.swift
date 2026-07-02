//
//  RounderApp.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import SwiftUI
import QuartzCore

// MARK: - Constants
struct RounderAppConstants {
    static let maxInstances = 3
    static let firstLaunchWindowSize = NSSize(width: 600, height: 500)
    static let minWindowSize = NSSize(width: 500, height: 450)
    static let settingsMinWindowSize = NSSize(width: 700, height: 600)
    static let defaultCornerRadius: Double = 20.0
    static let cornerSizePadding: CGFloat = 0.01
    static let settingsWindowSize = NSSize(width: 860, height: 820)
    static let threadSleepInterval: TimeInterval = 0.001
    static let cornerRadiusMin: Double = 0
    static let cornerRadiusMax: Double = 40
    static let cornerRadiusStep: Double = 1
}

// MARK: - UserDefaults Keys
struct UserDefaultsKeys {
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let cornerRadius = "cornerRadius"
    static let cornerColor = "cornerColor"
    static let isEnabled = "isEnabled"
    static let superGamingMode = "superGamingMode"
    static let gamingSpeed = "gamingSpeed"
    static let glowIntensity = "glowIntensity"
    static let bloomWidth = "bloomWidth"
    static let cornerCutoutStyle = "cornerCutoutStyle"
    static let topLeftEnabled = "topLeftEnabled"
    static let topRightEnabled = "topRightEnabled"
    static let bottomLeftEnabled = "bottomLeftEnabled"
    static let bottomRightEnabled = "bottomRightEnabled"
    static let selectedDisplayIDs = "selectedDisplayIDs"
}

struct OverlayConfiguration {
    var isEnabled: Bool
    var radius: Double
    var color: NSColor
    var superGamingMode: Bool
    var gamingSpeed: Double
    var glowIntensity: Double
    var bloomWidth: Double
    var cutoutStyle: CornerCutoutStyle
    var topLeftEnabled: Bool
    var topRightEnabled: Bool
    var bottomLeftEnabled: Bool
    var bottomRightEnabled: Bool
    var selectedDisplayIDs: [CGDirectDisplayID]

    static func current() -> OverlayConfiguration {
        let defaults = UserDefaults.standard
        let selectedDisplayIDs = loadSelectedDisplayIDs(from: defaults)

        return OverlayConfiguration(
            isEnabled: defaults.bool(forKey: UserDefaultsKeys.isEnabled, defaultValue: true),
            radius: defaults.object(forKey: UserDefaultsKeys.cornerRadius) as? Double ?? RounderAppConstants.defaultCornerRadius,
            color: loadColor(from: defaults),
            superGamingMode: defaults.bool(forKey: UserDefaultsKeys.superGamingMode, defaultValue: false),
            gamingSpeed: defaults.object(forKey: UserDefaultsKeys.gamingSpeed) as? Double ?? PresetManagerConstants.defaultGamingSpeed,
            glowIntensity: defaults.object(forKey: UserDefaultsKeys.glowIntensity) as? Double ?? PresetManagerConstants.defaultGlowIntensity,
            bloomWidth: defaults.object(forKey: UserDefaultsKeys.bloomWidth) as? Double ?? PresetManagerConstants.defaultBloomWidth,
            cutoutStyle: CornerCutoutStyle(
                rawValue: defaults.string(forKey: UserDefaultsKeys.cornerCutoutStyle) ?? ""
            ) ?? .rounded,
            topLeftEnabled: defaults.bool(forKey: UserDefaultsKeys.topLeftEnabled, defaultValue: true),
            topRightEnabled: defaults.bool(forKey: UserDefaultsKeys.topRightEnabled, defaultValue: true),
            bottomLeftEnabled: defaults.bool(forKey: UserDefaultsKeys.bottomLeftEnabled, defaultValue: true),
            bottomRightEnabled: defaults.bool(forKey: UserDefaultsKeys.bottomRightEnabled, defaultValue: true),
            selectedDisplayIDs: selectedDisplayIDs
        )
    }

    private static func loadColor(from defaults: UserDefaults) -> NSColor {
        guard let colorData = defaults.data(forKey: UserDefaultsKeys.cornerColor),
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
            return .black
        }
        return color
    }

    private static func loadSelectedDisplayIDs(from defaults: UserDefaults) -> [CGDirectDisplayID] {
        let connected = NSScreen.screens.compactMap { $0.displayID }

        var saved: [CGDirectDisplayID]? = nil
        if let data = defaults.data(forKey: UserDefaultsKeys.selectedDisplayIDs),
           let displayIDs = try? JSONDecoder().decode([UInt32].self, from: data) {
            saved = displayIDs.map { CGDirectDisplayID($0) }
        } else if let displayIDs = defaults.array(forKey: UserDefaultsKeys.selectedDisplayIDs) as? [UInt32] {
            saved = displayIDs.map { CGDirectDisplayID($0) }
        }

        guard let saved else {
            // 未設定：接続中のすべてのディスプレイを対象にする
            return connected
        }

        // ユーザーが意図的にすべてのモニターを解除した場合（空の選択）は、その意思を尊重して
        // どこにも角を出さない。空＝「全部」ではない点に注意（保存パスと再作成パスの不一致を防ぐ）。
        if saved.isEmpty {
            return []
        }

        // ディスプレイID は再接続やGPU切り替えで変わり得る。保存済みIDが（空ではないのに）
        // 現在のどのディスプレイとも一致しない場合は、全ディスプレイから角が消えるのを避けるため、
        // 接続中のすべてを対象にフォールバックする。
        let connectedSet = Set(connected)
        let stillValid = saved.filter { connectedSet.contains($0) }
        return stillValid.isEmpty ? connected : stillValid
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        object(forKey: key) as? Bool ?? defaultValue
    }
}

@main
struct RounderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    /// SwiftUI の @NSApplicationDelegateAdaptor 環境では NSApp.delegate が
    /// 転送用ラッパーになり `NSApplication.shared.delegate as? AppDelegate` が nil になる。
    /// そのため確実に参照できる共有インスタンスを保持する。
    static weak var shared: AppDelegate?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    var overlayWindows: [CornerOverlayWindow] = []
    /// ゲーミングモードのふち発光ウィンドウ（1スクリーン1枚・GPU合成）
    var glowWindows: [GamingGlowWindow] = []
    var settingsWindow: NSWindow?
    /// 初回起動セットアップ用ウィンドウ。settingsWindow とは別に保持しないと、
    /// 直後の setupSettingsWindow() で参照が上書きされ、閉じたときの処理ができなくなる。
    private var onboardingWindow: NSWindow?
    private var firstLaunchCompleted = false
    private var menuBarController = MenuBarController()

    private func preventMultipleInstances() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        // 実行中のインスタンス数が最大数を超えている場合は終了
        if runningApps.count > RounderAppConstants.maxInstances {
            // 既存のインスタンスを前面に持ってくる
            if let oldestApp = runningApps.first {
                oldestApp.activate(options: [.activateIgnoringOtherApps])
            }
            
            // このインスタンスを終了
            NSApplication.shared.terminate(nil)
            return true
        }
        
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 多重起動を防止
        if preventMultipleInstances() {
            return
        }
        
        setupApplication()
        
        // 初回起動チェック
        if isFirstLaunch() {
            showFirstLaunchSetup()
        } else {
            createOverlayWindows()
            setupMenuBar()
        }
        
        setupSettingsWindow()

        ScreenMonitor.shared.startMonitoring(appDelegate: self)

        // フルスクリーンSpaceへの切替時、先に作られたオーバーレイが前面から外れる
        // ことがあるため、Space変更を監視して常に前面へ再表示する。
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        for window in overlayWindows { window.orderFrontRegardless() }
        for window in glowWindows { window.orderFrontRegardless() }
    }
    
    private func isFirstLaunch() -> Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasLaunchedBefore)
    }
    
    private func setFirstLaunchComplete() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasLaunchedBefore)
    }
    
    private func showFirstLaunchSetup() {
        // Dockに表示されるように設定
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        let contentView = FirstLaunchSetupView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: RounderAppConstants.firstLaunchWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = String(localized: "window_title_setup")
        window.contentViewController = hostingController
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.minSize = RounderAppConstants.minWindowSize

        self.onboardingWindow = window
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
    }

    /// 初回セットアップ完了。再起動せずにそのままメニューバー常駐モードへ移行する。
    func completeFirstLaunchSetup() {
        firstLaunchCompleted = true
        setFirstLaunchComplete()

        onboardingWindow?.orderOut(nil)
        onboardingWindow?.close()
        onboardingWindow = nil

        createOverlayWindows()
        setupMenuBar()
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // すべてのオーバーレイウィンドウを明示的に閉じる
        closeOverlayWindows()
        
        // 設定ウィンドウも閉じる
        settingsWindow?.orderOut(nil)
        settingsWindow?.close()
        settingsWindow = nil
        
        // 画面監視を停止
        ScreenMonitor.shared.stopMonitoring()
        
        return .terminateNow
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 追加のクリーンアップ処理
        overlayWindows.removeAll()
        settingsWindow = nil
    }
    
    private func setupApplication() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func createOverlayWindows() {
        applyOverlayConfiguration(.current())
    }

    func applyOverlayConfiguration(_ configuration: OverlayConfiguration) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.applyOverlayConfiguration(configuration)
            }
            return
        }

        closeOverlayWindows()

        guard configuration.isEnabled else { return }

        // すべてのスクリーンを取得
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        // Squircle は円より角に沿って膨らむため、iOS 実機と同様に辺方向へ長く伸ばして描く。
        // ウィンドウを radius の 1.8 倍にすると、対角の深さが角丸とほぼ揃う（0.405r ≒ 0.414r）。
        let styleFactor: CGFloat = configuration.cutoutStyle == .squircle ? 1.8 : 1.0
        let cornerSize = CGFloat(configuration.radius) * styleFactor + RounderAppConstants.cornerSizePadding
        
        // 選択されたディスプレイのみにオーバーレイを作成
        for screen in screens {
            // このスクリーンのディスプレイIDを取得
            guard let displayID = screen.displayID else { continue }
            
            // 選択されたディスプレイかチェック
            if !configuration.selectedDisplayIDs.contains(displayID) {
                continue
            }
            
            let frame = screen.frame

            // 各角の「物理的な位置」と、その角を描画するときに使う CornerType の対応表。
            // CornerType は描画座標系（非フリップ）の都合で上下が反転している点に注意
            // （物理的な左上 → .bottomLeft など）。以前は window.screen から角を推測していたが、
            // マルチモニターで誤判定するため、生成時に確定した値を渡すようにした。
            // baseHue は周回上の位置（時計回りに 左上=0, 右上=0.25, 右下=0.5, 左下=0.75）。
            // これでふちの虹と角の色が連続してつながる。
            let cornerSpecs: [(enabled: Bool, origin: CGPoint, type: CornerType, baseHue: Double)] = [
                (configuration.topLeftEnabled,     CGPoint(x: frame.minX, y: frame.maxY - cornerSize),              .bottomLeft,  0.0),
                (configuration.topRightEnabled,    CGPoint(x: frame.maxX - cornerSize, y: frame.maxY - cornerSize), .bottomRight, 0.25),
                (configuration.bottomLeftEnabled,  CGPoint(x: frame.minX, y: frame.minY),                           .topLeft,     0.75),
                (configuration.bottomRightEnabled, CGPoint(x: frame.maxX - cornerSize, y: frame.minY),              .topRight,    0.5)
            ]

            for spec in cornerSpecs where spec.enabled {
                let window = CornerOverlayWindow(
                    corner: spec.origin,
                    size: cornerSize,
                    radius: CGFloat(configuration.radius),
                    color: configuration.color,
                    cutoutStyle: configuration.cutoutStyle,
                    cornerType: spec.type
                )
                overlayWindows.append(window)
                if configuration.superGamingMode {
                    window.setGamingMode(true, speed: configuration.gamingSpeed, baseHue: spec.baseHue)
                }
            }

            // ゲーミングモードでは、四隅に加えて画面のふち全体をGPU合成で発光させる（1スクリーン1枚）
            if configuration.superGamingMode {
                let glow = GamingGlowWindow(
                    screenFrame: frame,
                    speed: configuration.gamingSpeed,
                    glowIntensity: configuration.glowIntensity,
                    bloomWidth: configuration.bloomWidth
                )
                glowWindows.append(glow)
            }
        }
    }

    func recreateOverlayWindows() {
        createOverlayWindows()
    }

    private func closeOverlayWindows() {
        for window in overlayWindows {
            window.prepareForClose()
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()

        for window in glowWindows {
            window.prepareForClose()
            window.orderOut(nil)
            window.close()
        }
        glowWindows.removeAll()
    }
    
    func setupMenuBar() {
        menuBarController.setupMenuBar(appDelegate: self)
    }
    
    func setupSettingsWindow() {
        let settingsView = AdvancedSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: RounderAppConstants.settingsWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = String(localized: "window_title_settings")
        window.contentViewController = hostingController
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.minSize = RounderAppConstants.settingsMinWindowSize

        // 半透明（vibrancy）が背後まで抜けるようにウィンドウを透過させ、
        // タイトルバーもコンテンツと一体化させたモダンな外観にする。
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarSeparatorStyle = .none
        
        // ウィンドウが閉じられたときにDockから非表示にする
        window.delegate = self
        
                
        self.settingsWindow = window
    }
    
    func showSettings() {
        // 設定ウィンドウを開くときはDockに表示
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // 設定を開いている間も画面監視は継続する。監視の再作成は保存済み設定を読むだけで、
        // メインスレッド上で 0.5 秒デバウンスされるため手動の「適用」と競合しない。
        // 停止してしまうと、設定を開いている間のディスプレイ着脱を取りこぼしてしまう。
        ScreenMonitor.shared.startMonitoring(appDelegate: self)

        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示
        NSApp.setActivationPolicy(.accessory)
        settingsWindow?.orderOut(nil)
        ScreenMonitor.shared.startMonitoring(appDelegate: self)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }

        if closingWindow == settingsWindow {
            // 設定ウィンドウが閉じられたときにDockから非表示に戻す
            NSApp.setActivationPolicy(.accessory)
            // 画面変更監視を再開
            ScreenMonitor.shared.startMonitoring(appDelegate: self)
        } else if closingWindow == onboardingWindow {
            // 初期設定を完了せずに閉じた場合は、メニューバーもオーバーレイも未構築で
            // 操作不能になるため、アプリを終了する（次回起動で再度セットアップを表示）。
            if !firstLaunchCompleted {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
}
