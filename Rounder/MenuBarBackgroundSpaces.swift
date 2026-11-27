import AppKit

/// One window per desktop, rather than one window shared across desktops:
/// a shared window is composited only once during an interactive Space swipe.
enum MenuBarBackgroundSpaces {
    static func reconcile(_ windows: [MenuBarBackgroundWindow], screens: [NSScreen],
                          fullScreenDisplays: Set<CGDirectDisplayID>) -> [MenuBarBackgroundWindow] {
        var result: [MenuBarBackgroundWindow] = []
        for screen in screens {
            guard let displayID = screen.displayID else { continue }
            let existing = windows.filter { $0.overlayDisplayID == displayID }
            guard let template = existing.first else { continue }
            guard let ids = DesktopSpaceMembership.spaceIDs(for: displayID), !ids.isEmpty else {
                result.append(contentsOf: existing)
                continue
            }
            for id in ids {
                if let window = existing.first(where: { $0.desktopSpaceID == id }) {
                    result.append(window)
                } else {
                    result.append(template.sibling(on: screen, spaceID: id,
                                                  isFullScreen: fullScreenDisplays.contains(displayID)))
                }
            }
        }
        for removed in windows where !result.contains(where: { $0 === removed }) {
            removed.prepareForClose()
            removed.close()
        }
        return result
    }
}
