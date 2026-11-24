import AppKit

extension AppDelegate {
    /// A Space transition can change visibleFrame without changing displays.
    /// Preserve the same windows and overlay Space membership in that case.
    func refreshOverlayScreenGeometry(animated: Bool = false) {
        let screens = NSScreen.screens
        let frames = Dictionary(uniqueKeysWithValues: screens.compactMap { screen in
            screen.displayID.map { ($0, screen.frame) }
        })
        guard frames == overlayScreenFrames else {
            recreateOverlayWindows()
            return
        }
        let fullScreenDisplays = DisplaySpaceState.fullScreenDisplayIDs()
        for screen in screens {
            guard let displayID = screen.displayID else { continue }
            for window in menuBarBackgroundWindows where window.overlayDisplayID == displayID {
                window.updatePlacement(on: screen, isFullScreen: fullScreenDisplays.contains(displayID))
            }
            guard overlayExcludesMenuBar else { continue }
            let frame = CornerGeometry.overlayFrame(
                screenFrame: screen.frame, visibleFrame: screen.visibleFrame,
                excludeMenuBar: !fullScreenDisplays.contains(displayID)
            )
            for window in overlayWindows where window.overlayDisplayID == displayID {
                window.updatePlacement(in: frame, animated: animated)
            }
            for window in glowWindows where window.overlayDisplayID == displayID {
                window.updatePlacement(in: frame, animated: animated)
            }
        }
    }
}
