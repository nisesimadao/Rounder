import AppKit
import QuartzCore

extension AppDelegate {
    /// Alpha preserves both the window identity and its pinned overlay Space.
    /// Hiding/showing windows with orderOut would risk transition flicker.
    func applyMissionControlVisibility(_ activeDisplays: Set<CGDirectDisplayID>, animated: Bool = true) {
        // Give the strip and pinned corners the same short fade, matching the
        // menu background's transient appearance rather than snapping corners.
        updateFullscreenMenuMissionControl(activeDisplays)
        let duration = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0.18 : 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            for window in overlayWindows + desktopTopCornerWindows {
                let hide = overlayExcludesMenuBar && window.isTopCorner &&
                    window.overlayDisplayID.map(activeDisplays.contains) == true
                let opacity: CGFloat = hide ? 0 : 1
                if duration > 0 {
                    window.animator().alphaValue = opacity
                } else {
                    window.alphaValue = opacity
                }
            }
            for window in glowWindows {
                let hide = overlayExcludesMenuBar && window.isTopEdge &&
                    window.overlayDisplayID.map(activeDisplays.contains) == true
                let opacity: CGFloat = hide ? 0 : 1
                if duration > 0 {
                    window.animator().alphaValue = opacity
                } else {
                    window.alphaValue = opacity
                }
            }
            for window in menuBarBackgroundWindows {
                let opacity: CGFloat = activeDisplays.contains(window.overlayDisplayID) ? 0 : 1
                if duration > 0 {
                    window.animator().alphaValue = opacity
                } else {
                    window.alphaValue = opacity
                }
            }
        }
    }
}
