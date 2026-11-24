import AppKit

/// Stable IDs distinguish shipped presets from user-created presets, even when
/// the user chooses the same name. The catalog is installed once, not on launch.
enum BuiltInPresets {
    static func makePresets() -> [CornerPreset] {
        [
            CornerPreset(name: "Default", id: UUID(uuidString: "70BD1B2C-40C6-4BA0-9608-6F915D09C001")!),
            CornerPreset(name: "Virtual Desktops", pinToScreen: false, pinToDesktop: true,
                         id: UUID(uuidString: "70BD1B2C-40C6-4BA0-9608-6F915D09C002")!),
            CornerPreset(name: "Notched MacBook", pinToScreen: true, pinToDesktop: true,
                         excludeMenuBar: true, blackMenuBar: true,
                         id: UUID(uuidString: "70BD1B2C-40C6-4BA0-9608-6F915D09C003")!)
        ]
    }

    /// Older versions did not mark built-ins. Replace only the complete,
    /// unchanged six-preset catalog; keep edited and user-created presets.
    static func unchangedLegacyIDs(in presets: [CornerPreset]) -> Set<UUID> {
        let catalog: [(names: Set<String>, corners: [Bool])] = [
            (["All Corners", "すべての角"], [true, true, true, true]),
            (["Top Only", "上のみ"], [true, true, false, false]),
            (["Bottom Only", "下のみ"], [false, false, true, true]),
            (["Left Only", "左のみ"], [true, false, true, false]),
            (["Right Only", "右のみ"], [false, true, false, true]),
            (["None", "なし"], [false, false, false, false])
        ]
        var matches: [(UUID, Int)] = []
        for preset in presets {
            guard preset.cornerRadius == PresetManagerConstants.defaultCornerRadius,
                  preset.cornerNSColor.isEqual(NSColor.black), !preset.superGamingMode,
                  preset.gamingSpeed == PresetManagerConstants.defaultGamingSpeed,
                  preset.glowIntensity == PresetManagerConstants.defaultGlowIntensity,
                  preset.bloomWidth == PresetManagerConstants.defaultBloomWidth,
                  preset.cornerCutoutStyle == .rounded, preset.pinToScreen, !preset.pinToDesktop,
                  !preset.excludeMenuBar, !preset.blackMenuBar else { continue }
            let corners = [preset.topLeftEnabled, preset.topRightEnabled,
                           preset.bottomLeftEnabled, preset.bottomRightEnabled]
            if let index = catalog.firstIndex(where: { $0.names.contains(preset.name) && $0.corners == corners }) {
                matches.append((preset.id, index))
            }
        }
        guard matches.count == 6, Set(matches.map { $0.1 }).count == 6 else { return [] }
        return Set(matches.map { $0.0 })
    }
}
