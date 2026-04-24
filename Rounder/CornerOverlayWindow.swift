//
//  CornerOverlayWindow.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import Cocoa
import CoreGraphics

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
        
        super.init(
            contentRect: NSRect(origin: corner, size: CGSize(width: size, height: size)),
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
        
        let contentView = CornerOverlayView(radius: radius, color: color)
        self.contentView = contentView
        
        orderFront(nil)
    }
    
    func updateSettings(radius: CGFloat, color: NSColor) {
        self.radius = radius
        self.color = color
        
        if let contentView = contentView as? CornerOverlayView {
            contentView.updateSettings(radius: radius, color: color)
        }
    }
}

class CornerOverlayView: NSView {
    private var radius: CGFloat
    private var color: NSColor
    
    init(radius: CGFloat, color: NSColor) {
        self.radius = radius
        self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setFillColor(color.cgColor)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let bounds = self.bounds
        
        let cornerType = determineCornerType()
        
        // 描画モードを設定：重なり部分を透明に
        context.setBlendMode(.copy)
        
        // 正方形部分を描画
        context.fill(bounds)
        
        // 円部分を透明で描画（重なり部分をくり抜く）
        context.setBlendMode(.clear)
        let circlePath = createCirclePath(in: bounds, cornerType: cornerType)
        context.addPath(circlePath)
        context.fillPath()
        
        // 描画モードを元に戻す
        context.setBlendMode(.normal)
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
        self.radius = radius
        self.color = color
        needsDisplay = true
    }
}

enum CornerType {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
