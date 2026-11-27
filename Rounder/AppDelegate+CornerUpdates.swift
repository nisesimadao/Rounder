//
//  AppDelegate+CornerUpdates.swift
//  Rounder
//
//  Lightweight updates for settings that only change existing corner geometry.
//  Full configuration changes still go through applyOverlayConfiguration(),
//  which rebuilds the overlay/window set as before.
//

import Cocoa

extension AppDelegate {
    /// Update Radius / Radius Shape without destroying and recreating overlay
    /// windows. This is intended for live menu-bar controls.
    func updateCornerGeometry(radius: Double, cutoutStyle: CornerCutoutStyle) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateCornerGeometry(radius: radius, cutoutStyle: cutoutStyle)
            }
            return
        }

        let clampedRadius = min(
            max(radius, RounderAppConstants.cornerRadiusMin),
            RounderAppConstants.cornerRadiusMax
        )

        desktopTopCorners.updateGeometry(radius: CGFloat(clampedRadius), style: cutoutStyle)
        fullscreenMenuCorners.updateGeometry(radius: CGFloat(clampedRadius), style: cutoutStyle)
        let cornerSize = CornerGeometry.cornerSize(radius: CGFloat(clampedRadius), style: cutoutStyle)
        for window in menuBarBackgroundWindows { window.updateCornerSize(cornerSize) }
        for window in glowWindows { window.updateCornerSize(cornerSize) }

        for window in overlayWindows {
            window.updateGeometry(
                radius: CGFloat(clampedRadius),
                cutoutStyle: cutoutStyle
            )
        }
    }
}
