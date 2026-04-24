//
//  MenuBarController.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var appDelegate: AppDelegate?
    
    func setupMenuBar(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "R"
            button.toolTip = "Rounder - 画面コーナー角丸化ツール"
            
            let menu = NSMenu()
            
            menu.addItem(NSMenuItem.separator())
            
            let settingsItem = NSMenuItem(
                title: "設定...",
                action: #selector(showSettings),
                keyEquivalent: ","
            )
            settingsItem.target = self
            menu.addItem(settingsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(
                title: "終了",
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)
            
            statusItem?.menu = menu
        }
    }
    
    @objc private func showSettings() {
        appDelegate?.showSettings()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
