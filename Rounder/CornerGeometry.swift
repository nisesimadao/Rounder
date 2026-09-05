//
//  CornerGeometry.swift
//  Rounder
//
//  Shared corner-path math.
//  This file intentionally contains geometry only: no windows, persistence,
//  menu state, or drawing side effects. The functions mirror the existing
//  CornerOverlayView path calculations so overlay rendering and future preview
//  icons can use the same source of truth.
//

import Cocoa
import CoreGraphics

enum CornerGeometry {
    /// The filled quadrant used by the gaming corner layer for a rounded cutout.
    /// This is intentionally the same construction previously used by
    /// CornerOverlayView.createRoundedQuadrantPath.
    static func roundedQuadrantPath(
        in bounds: NSRect,
        radius: CGFloat,
        cornerType: CornerType
    ) -> CGPath {
        let center: CGPoint
        let startAngle: CGFloat

        switch cornerType {
        case .topLeft:
            center = CGPoint(x: bounds.maxX, y: bounds.maxY)
            startAngle = .pi
        case .topRight:
            center = CGPoint(x: bounds.minX, y: bounds.maxY)
            startAngle = .pi * 1.5
        case .bottomLeft:
            center = CGPoint(x: bounds.maxX, y: bounds.minY)
            startAngle = .pi * 0.5
        case .bottomRight:
            center = CGPoint(x: bounds.minX, y: bounds.minY)
            startAngle = 0
        }

        let path = CGMutablePath()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: startAngle + .pi * 0.5,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }

    /// Superellipse quadrant used by the squircle cutout.
    /// `bounds` is intentionally used as rx/ry exactly as the current overlay
    /// implementation does; the caller owns the 1.8x squircle window sizing.
    static func squircleCutoutPath(
        in bounds: NSRect,
        cornerType: CornerType
    ) -> CGPath {
        let n = 4.0
        let sx: CGFloat
        let sy: CGFloat
        let center: CGPoint

        switch cornerType {
        case .topLeft:
            center = CGPoint(x: bounds.maxX, y: bounds.maxY)
            sx = -1
            sy = -1
        case .topRight:
            center = CGPoint(x: bounds.minX, y: bounds.maxY)
            sx = 1
            sy = -1
        case .bottomLeft:
            center = CGPoint(x: bounds.maxX, y: bounds.minY)
            sx = -1
            sy = 1
        case .bottomRight:
            center = CGPoint(x: bounds.minX, y: bounds.minY)
            sx = 1
            sy = 1
        }

        let rx = bounds.width
        let ry = bounds.height
        let path = CGMutablePath()
        path.move(to: center)

        let steps = 72
        for i in 0...steps {
            let theta = Double(i) / Double(steps) * .pi / 2.0
            let x = Double(rx) * pow(cos(theta), 2.0 / n)
            let y = Double(ry) * pow(sin(theta), 2.0 / n)
            path.addLine(
                to: CGPoint(
                    x: center.x + sx * CGFloat(x),
                    y: center.y + sy * CGFloat(y)
                )
            )
        }

        path.closeSubpath()
        return path
    }

    /// Circular cutout path used by the normal (non-gaming) CGContext route.
    /// The circle deliberately extends outside `bounds`; clipping the clear fill
    /// to the view leaves the same visible quarter-circle as before.
    static func roundedCutoutPath(
        in bounds: NSRect,
        radius: CGFloat,
        cornerType: CornerType
    ) -> CGPath {
        let path = CGMutablePath()

        switch cornerType {
        case .topLeft:
            path.addEllipse(in: CGRect(
                x: bounds.maxX - radius,
                y: bounds.maxY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        case .topRight:
            path.addEllipse(in: CGRect(
                x: bounds.minX - radius,
                y: bounds.maxY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        case .bottomLeft:
            path.addEllipse(in: CGRect(
                x: bounds.maxX - radius,
                y: bounds.minY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        case .bottomRight:
            path.addEllipse(in: CGRect(
                x: bounds.minX - radius,
                y: bounds.minY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }

        return path
    }

    /// Triangular mask used by the polygon style.
    static func polygonMaskPath(
        in bounds: NSRect,
        radius: CGFloat,
        cornerType: CornerType
    ) -> CGPath {
        let path = CGMutablePath()
        let inset = min(radius, min(bounds.width, bounds.height))

        guard inset > 0 else {
            return path
        }

        let points: [CGPoint]
        switch cornerType {
        case .topLeft:
            points = [
                CGPoint(x: bounds.minX, y: bounds.minY),
                CGPoint(x: bounds.minX + inset, y: bounds.minY),
                CGPoint(x: bounds.minX, y: bounds.minY + inset)
            ]
        case .topRight:
            points = [
                CGPoint(x: bounds.maxX, y: bounds.minY),
                CGPoint(x: bounds.maxX - inset, y: bounds.minY),
                CGPoint(x: bounds.maxX, y: bounds.minY + inset)
            ]
        case .bottomLeft:
            points = [
                CGPoint(x: bounds.minX, y: bounds.maxY),
                CGPoint(x: bounds.minX + inset, y: bounds.maxY),
                CGPoint(x: bounds.minX, y: bounds.maxY - inset)
            ]
        case .bottomRight:
            points = [
                CGPoint(x: bounds.maxX, y: bounds.maxY),
                CGPoint(x: bounds.maxX - inset, y: bounds.maxY),
                CGPoint(x: bounds.maxX, y: bounds.maxY - inset)
            ]
        }

        path.addLines(between: points)
        path.closeSubpath()
        return path
    }
}
