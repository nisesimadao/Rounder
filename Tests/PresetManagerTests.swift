import AppKit

// Compile the production preset model and manager; use a temporary defaults suite.
// xcrun swiftc Tests/PresetManagerTests.swift Rounder/PresetManager.swift \
//   Rounder/BuiltInPresets.swift Rounder/CornerGeometry.swift \
//   Rounder/CornerOverlayWindow.swift Rounder/GamingGlow.swift \
//   -o /tmp/rounder-preset-manager-tests

enum RounderAppConstants {
    static let defaultCornerRadius = 20.0
    static let cornerSizePadding: CGFloat = 0.01
}
enum UserDefaultsKeys {
    static let topLeftEnabled = "topLeftEnabled"
    static let topRightEnabled = "topRightEnabled"
    static let bottomLeftEnabled = "bottomLeftEnabled"
    static let bottomRightEnabled = "bottomRightEnabled"
    static let cornerRadius = "cornerRadius"
    static let cornerColor = "cornerColor"
    static let superGamingMode = "superGamingMode"
    static let gamingSpeed = "gamingSpeed"
    static let glowIntensity = "glowIntensity"
    static let bloomWidth = "bloomWidth"
    static let cornerCutoutStyle = "cornerCutoutStyle"
    static let pinToScreen = "pinToScreen"
    static let pinToDesktop = "pinToDesktop"
    static let excludeMenuBar = "excludeMenuBar"
    static let blackMenuBar = "blackMenuBar"
}
final class AppDelegate {
    static var shared: AppDelegate?
    func recreateOverlayWindows() {}
}
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        object(forKey: key) == nil ? defaultValue : bool(forKey: key)
    }
}

@main
struct PresetManagerTests {
    static func main() throws {
        let suite = "Rounder.PresetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = PresetManager(defaults: defaults)
        precondition(manager.presets.map(\.name) == ["Default", "Virtual Desktops", "Notched MacBook"])
        let standard = manager.presets[0], virtual = manager.presets[1], notch = manager.presets[2]
        precondition(standard.pinToScreen && !standard.pinToDesktop && !standard.excludeMenuBar && !standard.blackMenuBar)
        precondition(!virtual.pinToScreen && virtual.pinToDesktop && !virtual.excludeMenuBar && !virtual.blackMenuBar)
        precondition(notch.pinToScreen && notch.pinToDesktop && notch.excludeMenuBar && notch.blackMenuBar)
        manager.applyPreset(notch)
        precondition(defaults.bool(forKey: UserDefaultsKeys.pinToScreen))
        precondition(defaults.bool(forKey: UserDefaultsKeys.pinToDesktop))
        precondition(defaults.bool(forKey: UserDefaultsKeys.excludeMenuBar))
        precondition(defaults.bool(forKey: UserDefaultsKeys.blackMenuBar))
        let captured = manager.createPresetFromCurrentSettings(name: "Custom")
        precondition(captured.pinToScreen && captured.pinToDesktop && captured.excludeMenuBar && captured.blackMenuBar)
        let decoded = try JSONDecoder().decode(CornerPreset.self, from: JSONEncoder().encode(captured))
        precondition(decoded.id == captured.id && decoded.blackMenuBar && decoded.excludeMenuBar && decoded.pinToDesktop)
        manager.applyPreset(standard)
        precondition(!defaults.bool(forKey: UserDefaultsKeys.blackMenuBar) && !defaults.bool(forKey: UserDefaultsKeys.excludeMenuBar))
        precondition(!defaults.bool(forKey: UserDefaultsKeys.pinToDesktop) && defaults.bool(forKey: UserDefaultsKeys.pinToScreen))

        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(captured)) as! [String: Any]
        for key in ["pinToScreen", "pinToDesktop", "excludeMenuBar", "blackMenuBar", "bloomWidth", "cornerCutoutStyle"] {
            legacy.removeValue(forKey: key)
        }
        let old = try JSONDecoder().decode(CornerPreset.self, from: JSONSerialization.data(withJSONObject: legacy))
        precondition(old.pinToScreen && !old.pinToDesktop && !old.excludeMenuBar && !old.blackMenuBar)
        precondition(old.bloomWidth == 1 && old.cornerCutoutStyle == .rounded)

        manager.deletePreset(notch)
        manager.addPreset(captured)
        let reopened = PresetManager(defaults: defaults)
        precondition(reopened.presets.count == 3 && !reopened.presets.contains { $0.id == notch.id })
        precondition(reopened.presets.contains { $0.id == captured.id })
        reopened.presets = []
        reopened.savePresets()
        precondition(PresetManager(defaults: defaults).presets.isEmpty, "Do not recreate presets deleted by the user")

        // A complete untouched legacy catalog can be replaced without deleting
        // a user's unrelated preset. Edited/incomplete catalogs must be kept.
        let legacySet = [
            CornerPreset(name: "All Corners"),
            CornerPreset(name: "Top Only", bottomLeftEnabled: false, bottomRightEnabled: false),
            CornerPreset(name: "Bottom Only", topLeftEnabled: false, topRightEnabled: false),
            CornerPreset(name: "Left Only", topRightEnabled: false, bottomRightEnabled: false),
            CornerPreset(name: "Right Only", topLeftEnabled: false, bottomLeftEnabled: false),
            CornerPreset(name: "None", topLeftEnabled: false, topRightEnabled: false, bottomLeftEnabled: false, bottomRightEnabled: false)
        ]
        precondition(BuiltInPresets.unchangedLegacyIDs(in: legacySet).count == 6)
        var edited = legacySet
        edited[0].cornerRadius = 31
        precondition(BuiltInPresets.unchangedLegacyIDs(in: edited).isEmpty)
        defaults.removeObject(forKey: "builtInPresetsVersion")
        defaults.set(try JSONEncoder().encode(legacySet + [captured]), forKey: PresetManagerConstants.presetsKey)
        let migrated = PresetManager(defaults: defaults)
        precondition(migrated.presets.count == 4 && migrated.presets.last?.id == captured.id)
        precondition(migrated.presets.prefix(3).map(\.name) == ["Default", "Virtual Desktops", "Notched MacBook"])
        print("PASS: factory presets, application/capture, legacy JSON, migration, custom preservation and deleted presets")
    }
}
