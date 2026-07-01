//
//  ScreenMonitor.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import Foundation

// MARK: - Constants
struct ScreenMonitorConstants {
    static let screenChangeDelay: TimeInterval = 0.5
}

class ScreenMonitor: NSObject {
    static let shared = ScreenMonitor()
    
    private var screenChangeObserver: NSObjectProtocol?
    private var appDelegate: AppDelegate?
    private var pendingScreenChangeWorkItem: DispatchWorkItem?
    private var isMonitoring = false
    
    private override init() {
        super.init()
    }
    
    func startMonitoring(appDelegate: AppDelegate) {
        stopMonitoring()

        self.appDelegate = appDelegate
        isMonitoring = true
        
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChanged()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        pendingScreenChangeWorkItem?.cancel()
        pendingScreenChangeWorkItem = nil

        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            screenChangeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
        
    private func handleScreenParametersChanged() {
        guard let appDelegate = appDelegate else { return }
        pendingScreenChangeWorkItem?.cancel()
        
        // マルチモニター対応：スクリーン構成が変わったらオーバーレイだけを再作成する
        let workItem = DispatchWorkItem { [weak self, weak appDelegate] in
            guard let self, self.isMonitoring else { return }
            appDelegate?.recreateOverlayWindows()
        }
        pendingScreenChangeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + ScreenMonitorConstants.screenChangeDelay, execute: workItem)
    }
    
    deinit {
        stopMonitoring()
    }
}
