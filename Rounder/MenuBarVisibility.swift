import AppKit
import SwiftUI

/// Persistent preference for whether Rounder owns a menu-bar status item.
/// Missing values intentionally default to true so existing users keep the
/// current behavior after upgrading.
enum MenuBarVisibilityPreference {
    static let key = "showMenuBarIcon"

    static var isVisible: Bool {
        UserDefaults.standard.bool(forKey: key, defaultValue: true)
    }

    /// SMAppService launches the main app with an Open Application Apple event
    /// whose property data identifies it as a login-item launch. This lets
    /// automatic login launches stay completely quiet while a normal Finder
    /// launch can intentionally reveal Settings.
    static var wasLaunchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else {
            return false
        }

        return event.eventID == kAEOpenApplication &&
            event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}

/// General-settings row. Like Launch at Login, this is an application-level
/// integration preference and takes effect immediately rather than waiting for
/// Apply / OK.
struct MenuBarVisibilityToggle: View {
    @AppStorage(MenuBarVisibilityPreference.key) private var showMenuBarIcon = true

    var body: some View {
        Toggle(isOn: $showMenuBarIcon) {
            Text(String(
                localized: "show_menu_bar_icon",
                defaultValue: "Show menu bar icon",
                table: "MenuBarVisibility"
            ))
        }
    }
}

extension AppDelegate {
    /// Capture the launch source while the Open Application Apple event is still
    /// available. A normal manual launch should open Settings regardless of the
    /// menu-bar preference; login-item launches should remain silent.
    func applicationWillFinishLaunching(_ notification: Notification) {
        let shouldOpenSettings = !MenuBarVisibilityPreference.wasLaunchedAsLoginItem

        guard shouldOpenSettings else { return }

        // Run after applicationDidFinishLaunching has created the overlays/menu
        // and completed the first-launch decision. First launch keeps showing the
        // onboarding window instead of stacking Settings on top of it.
        DispatchQueue.main.async { [weak self] in
            guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasLaunchedBefore) else {
                return
            }
            self?.showSettings()
        }
    }

    /// Finder sends a reopen Apple event when an already-running app is opened
    /// again. Opening Rounder.app is always an explicit request for Settings,
    /// whether the menu-bar icon is currently visible or hidden.
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettings()
        return false
    }
}
