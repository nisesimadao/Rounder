import AppKit

/// Uses WindowServer metadata only; no Accessibility or Screen Recording grant.
/// Mission Control moved from Dock to WindowManager on newer macOS versions.
final class MissionControlMonitor {
    private var timer: Timer?
    private var hostPIDs: Set<pid_t> = []
    private var hostObserver: NSObjectProtocol?
    private var onWindows: (([[String: Any]]) -> Void)?
    private var onChange: ((Set<CGDirectDisplayID>) -> Void)?
    private(set) var activeDisplayIDs: Set<CGDirectDisplayID> = []

    func start(onWindows: (([[String: Any]]) -> Void)? = nil, onChange: @escaping (Set<CGDirectDisplayID>) -> Void) {
        self.onWindows = onWindows
        self.onChange = onChange
        if timer == nil {
            refreshHostPIDs()
            hostObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
            ) { [weak self] notification in
                guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      ["com.apple.dock", "com.apple.WindowManager"].contains(application.bundleIdentifier ?? "") else { return }
                self?.refreshHostPIDs()
            }
            let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.refresh() }
            timer.tolerance = 0.015
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let hostObserver { NSWorkspace.shared.notificationCenter.removeObserver(hostObserver) }
        hostObserver = nil
        activeDisplayIDs = []
        onChange = nil
        onWindows = nil
    }

    private func refreshHostPIDs() {
        let applications = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock") +
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.WindowManager")
        hostPIDs = Set(applications.map(\.processIdentifier))
    }

    private func refresh() {
        guard let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]],
              let primary = NSScreen.screens.first else { return }
        let screens = Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
            screen.displayID.map { ($0, CGRect(x: screen.frame.minX,
                y: primary.frame.maxY - screen.frame.maxY,
                width: screen.frame.width, height: screen.frame.height)) }
        })
        let active = Self.activeDisplays(windows: windows, hostPIDs: hostPIDs, screenBounds: screens)
        if active != activeDisplayIDs {
            activeDisplayIDs = active
            onChange?(active)
        }
        onWindows?(windows)
    }

    /// Layer-18 full-display shields are present for Mission Control/App Exposé.
    /// Match owner PIDs (not localized names) and reject small/offscreen surfaces.
    static func activeDisplays(
        windows: [[String: Any]], hostPIDs: Set<pid_t>, screenBounds: [CGDirectDisplayID: CGRect]
    ) -> Set<CGDirectDisplayID> {
        var result: Set<CGDirectDisplayID> = []
        for window in windows {
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t, hostPIDs.contains(pid),
                  window[kCGWindowLayer as String] as? Int == 18,
                  (window[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds) else { continue }
            // Window names may be redacted without Screen Recording permission.
            if let name = window[kCGWindowName as String] as? String, !name.isEmpty,
               name.range(of: "expose", options: .caseInsensitive) == nil { continue }
            for (displayID, screen) in screenBounds {
                if abs(rect.minX - screen.minX) <= 2 && abs(rect.minY - screen.minY) <= 2 &&
                    abs(rect.width - screen.width) <= 2 && abs(rect.height - screen.height) <= 2 {
                    result.insert(displayID)
                }
            }
        }
        return result
    }

    deinit {
        timer?.invalidate()
        if let hostObserver { NSWorkspace.shared.notificationCenter.removeObserver(hostObserver) }
    }
}
