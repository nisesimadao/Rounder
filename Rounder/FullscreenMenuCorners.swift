import AppKit

/// Rounds the application area below a temporarily revealed fullscreen menu.
/// Uses the existing Mission Control window snapshot; it does not inspect or
/// control the fullscreen app's title bar.
final class FullscreenMenuCorners {
    private var configuration: DesktopTopCorners.Configuration?
    private var fullscreen: Set<CGDirectDisplayID> = []
    private var missionControl: Set<CGDirectDisplayID> = []
    private var windows: [CGDirectDisplayID: [CornerOverlayWindow]] = [:]
    var overlayWindows: [CornerOverlayWindow] { windows.values.flatMap { $0 } }

    func configure(_ configuration: DesktopTopCorners.Configuration?, fullscreen: Set<CGDirectDisplayID>) {
        close()
        self.configuration = configuration
        self.fullscreen = fullscreen
    }

    func setFullscreenDisplays(_ displays: Set<CGDirectDisplayID>) {
        fullscreen = displays
        for (id, corners) in windows where !displays.contains(id) {
            for window in corners { window.alphaValue = 0 }
        }
    }

    func setMissionControlDisplays(_ displays: Set<CGDirectDisplayID>) {
        missionControl = displays
        for (id, corners) in windows where displays.contains(id) {
            for window in corners { window.alphaValue = 0 }
        }
    }

    /// Quartz coordinates: visible menu depth is its lower edge, clipped to the
    /// display top. Hidden menus above the display contribute no inset.
    static func visibleInsets(windows: [[String: Any]], screens: [CGDirectDisplayID: CGRect]) -> [CGDirectDisplayID: CGFloat] {
        var result: [CGDirectDisplayID: CGFloat] = [:]
        for window in windows {
            guard window[kCGWindowLayer as String] as? Int == Int(CGWindowLevelForKey(.mainMenuWindow)),
                  (window[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds), rect.height > 0, rect.height <= 100 else { continue }
            for (id, screen) in screens {
                guard abs(rect.minX - screen.minX) < 2, abs(rect.width - screen.width) < 2,
                      rect.minY <= screen.minY + 1, rect.maxY > screen.minY else { continue }
                result[id] = max(result[id] ?? 0, min(rect.maxY - screen.minY, rect.height))
            }
        }
        return result
    }

    func observe(_ snapshot: [[String: Any]], screens: [NSScreen] = NSScreen.screens) {
        guard let configuration, let primary = screens.first else { return }
        let quartzFrames = Dictionary(uniqueKeysWithValues: screens.compactMap { screen in
            screen.displayID.map { ($0, CGRect(x: screen.frame.minX, y: primary.frame.maxY - screen.frame.maxY,
                                              width: screen.frame.width, height: screen.frame.height)) }
        })
        let insets = Self.visibleInsets(windows: snapshot, screens: quartzFrames)
        for screen in screens {
            guard let id = screen.displayID, configuration.displayIDs.contains(id) else { continue }
            let inset = fullscreen.contains(id) && !missionControl.contains(id) ? (insets[id] ?? 0) : 0
            guard inset > 0 else {
                for window in windows[id] ?? [] { window.alphaValue = 0 }
                continue
            }
            let frame = NSRect(x: screen.frame.minX, y: screen.frame.minY,
                               width: screen.frame.width, height: screen.frame.height - inset)
            if windows[id] == nil {
                var corners: [CornerOverlayWindow] = []
                let size = CornerGeometry.cornerSize(radius: configuration.radius, style: configuration.style)
                for right in [false, true] where right ? configuration.topRight : configuration.topLeft {
                    let corner: ScreenCorner = right ? .topRight : .topLeft
                    let window = CornerOverlayWindow(corner: CornerGeometry.windowOrigin(in: frame, corner: corner, cornerSize: size),
                        size: size, radius: configuration.radius, color: configuration.color,
                        cutoutStyle: configuration.style, cornerType: corner.drawingCorner)
                    window.overlayDisplayID = id
                    window.alphaValue = 0
                    window.setGamingMode(configuration.gaming, speed: configuration.speed, baseHue: corner.gamingBaseHue)
                    corners.append(window)
                }
                OverlaySpace.pin(corners)
                windows[id] = corners
            }
            for window in windows[id] ?? [] {
                window.updatePlacement(in: frame)
                window.alphaValue = 1
            }
        }
    }

    func updateGeometry(radius: CGFloat, style: CornerCutoutStyle) {
        configuration?.radius = radius
        configuration?.style = style
        for corners in windows.values {
            for window in corners { window.updateGeometry(radius: radius, cutoutStyle: style) }
        }
    }

    func close() {
        for corners in windows.values {
            for window in corners { window.prepareForClose(); window.close() }
        }
        windows = [:]
        configuration = nil
        fullscreen = []
        missionControl = []
    }
}
