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
        refreshMenuBarBackgroundSpaces(fullScreenDisplays: fullScreenDisplays)
        for screen in screens {
            guard let displayID = screen.displayID else { continue }
            // Desktop corners must also survive fullscreen in normal mode.
            let windows: [NSWindow] = overlayWindows.filter { $0.overlayDisplayID == displayID } +
                glowWindows.filter { $0.overlayDisplayID == displayID }
            for window in windows {
                if fullScreenDisplays.contains(displayID) {
                    guard !window.collectionBehavior.contains(.stationary) else { continue }
                    temporaryScreenAttachments[window.windowNumber] = (window.collectionBehavior, window.level)
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                    window.level = .screenSaver
                    OverlaySpace.pin([window])
                } else if let original = temporaryScreenAttachments[window.windowNumber] {
                    // Retry on the settled Space notification if WindowServer is not ready yet.
                    if OverlayAttachmentRestoration.restore(window, behavior: original.behavior, level: original.level,
                        move: { OverlaySpace.attachToCurrentDesktop([window], displayID: displayID) }) {
                        temporaryScreenAttachments.removeValue(forKey: window.windowNumber)
                    }
                }
            }
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
