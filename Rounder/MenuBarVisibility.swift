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

    /// The Open Application Apple event identifies login-item launches through
    /// keyAELaunchedAsLogInItem. Read this from applicationDidFinishLaunching,
    /// while AppKit is handling the launch event.
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
