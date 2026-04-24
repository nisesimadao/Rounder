//
//  ScreenMonitor.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import Foundation

class ScreenMonitor: NSObject {
    static let shared = ScreenMonitor()
    
    private var screenChangeObserver: NSObjectProtocol?
    private var appDelegate: AppDelegate?
    
    private override init() {
        super.init()
    }
    
    func startMonitoring(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChanged()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    func stopMonitoring() {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            screenChangeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func screenParametersChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.handleScreenParametersChanged()
        }
    }
    
    @objc private func screenConfigurationChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.handleScreenParametersChanged()
        }
    }
    
    private func handleScreenParametersChanged() {
        guard let appDelegate = appDelegate else { return }
        
        appDelegate.overlayWindows.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            appDelegate.createOverlayWindows()
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
