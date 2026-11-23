import AppKit

extension AppDelegate {
    /// A Space transition can change visibleFrame without changing displays.
    /// Preserve the same windows and overlay Space membership in that case.
    func refreshOverlayScreenGeometry() {
        let screens = NSScreen.screens
        let frames = Dictionary(uniqueKeysWithValues: screens.compactMap { screen in
            screen.displayID.map { ($0, screen.frame) }
        })
        guard frames == overlayScreenFrames else {
            recreateOverlayWindows()
            return
        }
        guard overlayExcludesMenuBar else { return }
        for screen in screens {
            guard let displayID = screen.displayID else { continue }
            let frame = CornerGeometry.overlayFrame(
                screenFrame: screen.frame, visibleFrame: screen.visibleFrame, excludeMenuBar: true
            )
            for window in overlayWindows where window.overlayDisplayID == displayID {
                window.updatePlacement(in: frame)
            }
            for window in glowWindows where window.overlayDisplayID == displayID {
                window.updatePlacement(in: frame)
            }
        }
    }
}
