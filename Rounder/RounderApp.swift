//
//  RounderApp.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import SwiftUI
import QuartzCore

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
    var overlayWindows: [CornerOverlayWindow] = []
    var settingsWindow: NSWindow?
    private var menuBarController = MenuBarController()
    private var selectedDisplayIDs: [CGDirectDisplayID] = []
    private let maxInstances = 3  // 最大インスタンス数
    
    private func preventMultipleInstances() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        // 実行中のインスタンス数が最大数を超えている場合は終了
        if runningApps.count > maxInstances {
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
    }
    
    private func isFirstLaunch() -> Bool {
        return !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }
    
    private func setFirstLaunchComplete() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
    }
    
    private func showFirstLaunchSetup() {
        // Dockに表示されるように設定
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        let contentView = FirstLaunchSetupView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Rounder 初期設定"
        window.contentViewController = hostingController
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 450)
        
        self.settingsWindow = window
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // すべてのオーバーレイウィンドウを明示的に閉じる
        for window in overlayWindows {
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()
        
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
        // 既存のウィンドウをクリア
        overlayWindows.removeAll()
        
        // 選択されたディスプレイIDを読み込み
        loadSelectedDisplays()
        
        // すべてのスクリーンを取得
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        // @AppStorageから現在の設定を読み込み
        let radius = UserDefaults.standard.object(forKey: "cornerRadius") as? Double ?? 20.0
        let cornerSize: CGFloat = CGFloat(radius) + 0.01  // 余白が残らないように半径と同じサイズ
        let color: NSColor = {
            guard let colorData = UserDefaults.standard.data(forKey: "cornerColor"),
                  let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
                return .black
            }
            return nsColor
        }()
        
        // スーパーゲーミングモード設定を読み込み
        let superGamingMode = UserDefaults.standard.bool(forKey: "superGamingMode")
        let gamingSpeed = UserDefaults.standard.object(forKey: "gamingSpeed") as? Double ?? 1.0
        let glowIntensity = UserDefaults.standard.object(forKey: "glowIntensity") as? Double ?? 1.0
        
        // 四つの角の表示設定を読み込み
        let topLeftEnabled = UserDefaults.standard.bool(forKey: "topLeftEnabled")
        let topRightEnabled = UserDefaults.standard.bool(forKey: "topRightEnabled")
        let bottomLeftEnabled = UserDefaults.standard.bool(forKey: "bottomLeftEnabled")
        let bottomRightEnabled = UserDefaults.standard.bool(forKey: "bottomRightEnabled")
        
        // 選択されたディスプレイのみにオーバーレイを作成
        for screen in screens {
            // このスクリーンのディスプレイIDを取得
            guard let displayID = screen.displayID else { continue }
            
            // 選択されたディスプレイかチェック
            if !selectedDisplayIDs.contains(displayID) {
                continue
            }
            
            let frame = screen.frame
            
            // 左上
            if topLeftEnabled {
                let topLeftWindow = CornerOverlayWindow(
                    corner: CGPoint(x: frame.minX, y: frame.maxY - cornerSize),
                    size: cornerSize,
                    radius: CGFloat(radius),
                    color: color
                )
                overlayWindows.append(topLeftWindow)
                if superGamingMode {
                    topLeftWindow.setGamingMode(true, speed: gamingSpeed, glowIntensity: glowIntensity)
                }
            }
            
            // 右上
            if topRightEnabled {
                let topRightWindow = CornerOverlayWindow(
                    corner: CGPoint(x: frame.maxX - cornerSize, y: frame.maxY - cornerSize),
                    size: cornerSize,
                    radius: CGFloat(radius),
                    color: color
                )
                overlayWindows.append(topRightWindow)
                if superGamingMode {
                    topRightWindow.setGamingMode(true, speed: gamingSpeed, glowIntensity: glowIntensity)
                }
            }
            
            // 左下
            if bottomLeftEnabled {
                let bottomLeftWindow = CornerOverlayWindow(
                    corner: CGPoint(x: frame.minX, y: frame.minY),
                    size: cornerSize,
                    radius: CGFloat(radius),
                    color: color
                )
                overlayWindows.append(bottomLeftWindow)
                if superGamingMode {
                    bottomLeftWindow.setGamingMode(true, speed: gamingSpeed, glowIntensity: glowIntensity)
                }
            }
            
            // 右下
            if bottomRightEnabled {
                let bottomRightWindow = CornerOverlayWindow(
                    corner: CGPoint(x: frame.maxX - cornerSize, y: frame.minY),
                    size: cornerSize,
                    radius: CGFloat(radius),
                    color: color
                )
                overlayWindows.append(bottomRightWindow)
                if superGamingMode {
                    bottomRightWindow.setGamingMode(true, speed: gamingSpeed, glowIntensity: glowIntensity)
                }
            }
        }
    }
    
    func setupMenuBar() {
        menuBarController.setupMenuBar(appDelegate: self)
    }
    
    func setupSettingsWindow() {
        let settingsView = AdvancedSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Rounder 設定"
        window.contentViewController = hostingController
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 450)
        
        // モダンなウィンドウ外観に設定
        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }
        
        // ウィンドウが閉じられたときにDockから非表示にする
        window.delegate = self
        
        // コンテンツサイズに応じてウィンドウを自動リサイズ
        window.setContentSize(hostingController.view.intrinsicContentSize)
        
        // SwiftUIのビューが変更されたときにウィンドウサイズを更新
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: hostingController.view,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateWindowSizeToFitContent(window: window, view: hostingController.view)
            }
        }
        
                
        self.settingsWindow = window
    }
    
    private func updateWindowSizeToFitContent(window: NSWindow, view: NSView) {
        // SwiftUIビューの実際の必要サイズを計算
        let fittingSize = view.fittingSize
        
        // 最小サイズ制約を考慮
        let targetWidth = max(fittingSize.width + 40, window.minSize.width) // 余白を追加
        let targetHeight = max(fittingSize.height + 40, window.minSize.height)
        
        let currentFrame = window.frame
        
        // サイズが実際に変更されている場合のみ更新
        if abs(currentFrame.size.width - targetWidth) > 1 || abs(currentFrame.size.height - targetHeight) > 1 {
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y - (targetHeight - currentFrame.size.height),
                width: targetWidth,
                height: targetHeight
            )
            
            // 美しいアニメーション付きでウィンドウサイズを変更
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            })
        }
    }
    
    func showSettings() {
        // 設定ウィンドウを開くときはDockに表示
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // 設定画面を開いている間は画面変更監視を停止
        ScreenMonitor.shared.stopMonitoring()
        
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideSettings() {
        // 設定ウィンドウを閉じるときはDockから非表示
        NSApp.setActivationPolicy(.accessory)
        settingsWindow?.orderOut(nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // 設定ウィンドウが閉じられたときにDockから非表示に戻す
        if notification.object as? NSWindow == settingsWindow {
            NSApp.setActivationPolicy(.accessory)
            // 画面変更監視を再開
            ScreenMonitor.shared.startMonitoring(appDelegate: self)
        }
    }
    
    func updateOverlaySettings(radius: CGFloat, color: NSColor) {
        // パフォーマンス最適化：ウィンドウを再利用して再作成を避ける
        if overlayWindows.isEmpty {
            createOverlayWindows()
        }
        
        // 既存のウィンドウの設定を更新
        for window in overlayWindows {
            window.updateSettings(radius: radius, color: color)
            // 強制的に再描画を実行
            window.contentView?.needsDisplay = true
            
            // メインスレッドで確実に更新
            DispatchQueue.main.async {
                window.display()
                window.orderFront(nil)
            }
        }
        
        // UserDefaultsへの保存は@AppStorageに任せる（二重書き込みを避ける）
    }
    
    func updateGamingMode(enabled: Bool, speed: Double, glowIntensity: Double) {
        // パフォーマンス最適化：バックグラウンドスレッドで順次更新
        DispatchQueue.global(qos: .userInteractive).async {
            for window in self.overlayWindows {
                DispatchQueue.main.async {
                    window.setGamingMode(enabled, speed: speed, glowIntensity: glowIntensity)
                }
                // 少し待機してUIスレッドの負荷を分散
                Thread.sleep(forTimeInterval: 0.001)
            }
        }
    }
    
    func updateCornerVisibility(topLeft: Bool, topRight: Bool, bottomLeft: Bool, bottomRight: Bool) {
        // 設定を保存
        UserDefaults.standard.set(topLeft, forKey: "topLeftEnabled")
        UserDefaults.standard.set(topRight, forKey: "topRightEnabled")
        UserDefaults.standard.set(bottomLeft, forKey: "bottomLeftEnabled")
        UserDefaults.standard.set(bottomRight, forKey: "bottomRightEnabled")
        
        // すべてのウィンドウを一度削除して再作成
        for window in overlayWindows {
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()
        
        // 新しい設定でウィンドウを再作成
        createOverlayWindows()
    }
    
    func updateSelectedDisplays(_ displayIDs: [CGDirectDisplayID]) {
        selectedDisplayIDs = displayIDs
    }
    
    private func loadSelectedDisplays() {
        if let savedDisplayIDs = UserDefaults.standard.array(forKey: "selectedDisplayIDs") as? [UInt32] {
            selectedDisplayIDs = savedDisplayIDs.map { CGDirectDisplayID($0) }
        } else {
            // デフォルトですべてのディスプレイを選択
            selectedDisplayIDs = NSScreen.screens.compactMap { $0.displayID }
        }
    }
    
    func restartApplication() {
        // アプリのバンドルパスを取得
        let bundlePath = Bundle.main.bundlePath
        
        // NSTaskを使用して新しいインスタンスとして再起動
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundlePath] // -n で新しいインスタンスとして開く
        
        // バックグラウンドで実行し、アプリを終了
        DispatchQueue.global().async {
            do {
                try task.run()
                
                // タスクが開始されたらアプリを終了
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                print("Failed to restart application: \(error)")
                
                // フォールバック：シェルスクリプト方式
                self.restartWithShellScript()
            }
        }
    }
    
    private func restartWithShellScript() {
        // フォールバックとしてシェルスクリプト方式を使用
        let bundlePath = Bundle.main.bundlePath
        let shellScript = """
        #!/bin/bash
        sleep 0.5
        open "\(bundlePath)"
        exit 0
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let scriptFile = tempDir.appendingPathComponent("restart_rounder.sh")
        
        do {
            try shellScript.write(to: scriptFile, atomically: true, encoding: .utf8)
            
            // 実行権限を付与
            let chmodProcess = Process()
            chmodProcess.launchPath = "/bin/chmod"
            chmodProcess.arguments = ["+x", scriptFile.path]
            chmodProcess.launch()
            chmodProcess.waitUntilExit()
            
            // シェルスクリプトを実行
            let scriptProcess = Process()
            scriptProcess.launchPath = scriptFile.path
            scriptProcess.arguments = []
            
            DispatchQueue.global().async {
                do {
                    try scriptProcess.run()
                    
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                } catch {
                    print("Shell script restart failed: \(error)")
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            
        } catch {
            print("Failed to create restart script: \(error)")
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
