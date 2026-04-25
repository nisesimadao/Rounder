//
//  RounderApp.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import SwiftUI

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        window.maxSize = NSSize(width: 800, height: 700)
        
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
        guard let screen = NSScreen.main else { return }
        
        let radius = UserDefaults.standard.object(forKey: "cornerRadius") as? Double ?? 20.0
        let cornerSize: CGFloat = CGFloat(radius) + 0.01  // 余白が残らないように半径と同じサイズ
        let color: NSColor = {
            guard let colorData = UserDefaults.standard.data(forKey: "cornerColor"),
                  let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
                return .black
            }
            return nsColor
        }()
        
        let frame = screen.frame
        let corners = [
            CGPoint(x: frame.minX, y: frame.maxY - cornerSize),
            CGPoint(x: frame.maxX - cornerSize, y: frame.maxY - cornerSize),
            CGPoint(x: frame.minX, y: frame.minY),
            CGPoint(x: frame.maxX - cornerSize, y: frame.minY)
        ]
        
        for corner in corners {
            let window = CornerOverlayWindow(corner: corner, size: cornerSize, radius: CGFloat(radius), color: color)
            overlayWindows.append(window)
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
        window.minSize = NSSize(width: 420, height: 400)
        window.maxSize = NSSize(width: 1000, height: 1000)
        
        // モダンなウィンドウ外観に設定
        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }
        
        // ウィンドウが閉じられたときにDockから非表示にする
        window.delegate = self
        
        self.settingsWindow = window
    }
    
    func showSettings() {
        // 設定ウィンドウを開くときはDockに表示
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
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
        }
    }
    
    func updateOverlaySettings(radius: CGFloat, color: NSColor) {
        // 既存のウィンドウを削除
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        
        // 設定を一時的に保存
        UserDefaults.standard.set(Double(radius), forKey: "cornerRadius")
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "cornerColor")
        }
        
        // 新しいウィンドウを作成
        createOverlayWindows()
    }
}
