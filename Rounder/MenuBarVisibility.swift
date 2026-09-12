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
    /// whose property data identifies it as a login-item launch. This lets a
    /// hidden-menu-bar configuration stay completely quiet at login while a
    /// normal Finder launch can still recover the Settings window.
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
                table: "MenuBarVisibility",
                defaultValue: "Show menu bar icon"
            ))
        }
    }
}

extension AppDelegate {
    /// Finder sends a reopen Apple event when an already-running app is opened
    /// again. With the status item hidden, Settings becomes the intentional
    /// recovery surface without changing the user's menu-bar preference.
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        guard !MenuBarVisibilityPreference.isVisible else {
            return true
        }

        showSettings()
        return false
    }
}
