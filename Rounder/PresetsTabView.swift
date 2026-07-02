//
//  PresetsTabView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Constants
struct PresetsTabViewConstants {
    static let mainSpacing: CGFloat = 20
    static let headerSpacing: CGFloat = 4
    static let buttonSpacing: CGFloat = 8
}

struct PresetsTabView: View {
    @StateObject private var presetManager = PresetManager()
    @State private var showingAddPresetSheet = false
    @State private var newPresetName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var presetToEdit: CornerPreset?
    @State private var editingPresetName = ""
    
    // 複数選択用の状態
    @State private var selectionMode = false
    @State private var selectedPresets: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: PresetsTabViewConstants.mainSpacing) {
            // ヘッダー部分
            HStack {
                VStack(alignment: .leading, spacing: PresetsTabViewConstants.headerSpacing) {
                    Text("presets")
                        .font(.headline)
                    
                    if selectionMode {
                        HStack(spacing: PresetsTabViewConstants.buttonSpacing) {
                            Text(String(format: String(localized: "%lld selected"), selectedPresets.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("clear_selection") {
                                selectedPresets.removeAll()
                                selectionMode = false
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if selectionMode {
                        // 選択モード時のボタン
                        Button("cancel_selection") {
                            selectedPresets.removeAll()
                            selectionMode = false
                        }
                        .buttonStyle(.bordered)
                        
                        Button("export_selected") {
                            exportSelectedPresets()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedPresets.isEmpty)
                    } else {
                        // 通常モード時のボタン（一時的に選択・エクスポート・インポートボタンを非表示）
                        Button("current_settings_preset") {
                            newPresetName = ""
                            showingAddPresetSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // プリセットリスト（外側の連続スクロールに載るため、ここでは自前でスクロールしない）
            VStack(spacing: 12) {
                    ForEach(presetManager.presets) { preset in
                        PresetRowView(
                            preset: preset,
                            selectionMode: selectionMode,
                            isSelected: selectedPresets.contains(preset.id),
                            onToggleSelection: {
                                if selectedPresets.contains(preset.id) {
                                    selectedPresets.remove(preset.id)
                                } else {
                                    selectedPresets.insert(preset.id)
                                }
                            },
                            onApply: {
                                presetManager.applyPreset(preset)
                                alertMessage = String(format: String(localized: "preset_applied"), preset.name)
                                showingAlert = true
                            },
                            onEdit: {
                                presetToEdit = preset
                                editingPresetName = preset.name
                            },
                            onDelete: {
                                presetManager.deletePreset(preset)
                                selectedPresets.remove(preset.id)
                                alertMessage = String(format: String(localized: "preset_deleted"), preset.name)
                                showingAlert = true
                            }
                        )
                    }
            }
        }
        .sheet(isPresented: $showingAddPresetSheet) {
            AddPresetSheet(
                presetName: $newPresetName,
                onSave: { name in
                    let preset = presetManager.createPresetFromCurrentSettings(name: name)
                    presetManager.addPreset(preset)
                    alertMessage = String(format: String(localized: "preset_created"), name)
                    showingAlert = true
                }
            )
        }
        .sheet(item: $presetToEdit) { preset in
            EditPresetTabView(
                preset: .constant(preset),
                onSave: { updatedPreset in
                    presetManager.updatePreset(updatedPreset)
                    alertMessage = String(format: String(localized: "preset_updated"), updatedPreset.name)
                    showingAlert = true
                },
                onCancel: {
                    // キャンセル時は何もしない
                }
            )
        }
        .alert(String(localized: "preset_alert"), isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportSelectedPresets() {
        let selectedPresetObjects = presetManager.presets.filter { selectedPresets.contains($0.id) }
        
        if selectedPresetObjects.isEmpty {
            alertMessage = String(localized: "no_presets_selected")
            showingAlert = true
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(selectedPresetObjects)
            
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "rounder_selected_presets.json"
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try data.write(to: url)
                alertMessage = String(format: String(localized: "export_selected_success"), selectedPresetObjects.count)
                selectedPresets.removeAll()
                selectionMode = false
            } else {
                alertMessage = String(localized: "export_cancelled")
            }
        } catch {
            print("Failed to export selected presets: \(error)")
            alertMessage = String(localized: "export_failed")
        }
        showingAlert = true
    }
}

struct PresetRowView: View {
    let preset: CornerPreset
    let selectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onApply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // プリセット名と操作ボタン
            HStack {
                // 選択モードのチェックボックス
                if selectionMode {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // 角の状態を視覚的に表示
                    HStack(spacing: 8) {
                        CornerStatusIndicator(isEnabled: preset.topLeftEnabled, position: "topLeft")
                        CornerStatusIndicator(isEnabled: preset.topRightEnabled, position: "topRight")
                        CornerStatusIndicator(isEnabled: preset.bottomLeftEnabled, position: "bottomLeft")
                        CornerStatusIndicator(isEnabled: preset.bottomRightEnabled, position: "bottomRight")
                    }
                }
                
                Spacer()
                
                if !selectionMode {
                    HStack(spacing: 8) {
                        Button("apply") {
                            onApply()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("edit") {
                            onEdit()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("delete") {
                            onDelete()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                    }
                }
            }
            
            // 設定詳細
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(preset.cornerSwiftUIColor)
                        .frame(width: 12, height: 12)
                    Text("radius: \(Int(preset.cornerRadius))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(String(format: String(localized: "shape_detail"), preset.cornerCutoutStyle.localizedDisplayName))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if preset.superGamingMode {
                    Text("super_gaming_mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            selectionMode && isSelected 
                ? Color.accentColor.opacity(0.1)
                : Color(NSColor.controlBackgroundColor)
        )
        .cornerRadius(8)
        .overlay(
            selectionMode && isSelected
                ? RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 2)
                : nil
        )
    }
}

struct CornerStatusIndicator: View {
    let isEnabled: Bool
    let position: String
    
    var body: some View {
        Group {
            switch position {
            case "topLeft":
                Image(systemName: "square.grid.3x3.topleft.fill")
            case "topRight":
                Image(systemName: "square.grid.3x3.topright.fill")
            case "bottomLeft":
                Image(systemName: "square.grid.3x3.bottomleft.fill")
            case "bottomRight":
                Image(systemName: "square.grid.3x3.bottomright.fill")
            default:
                Image(systemName: "square")
            }
        }
        .font(.caption)
        .foregroundColor(isEnabled ? .primary : .secondary)
        .opacity(isEnabled ? 1.0 : 0.3)
    }
}

struct AddPresetSheet: View {
    @Binding var presetName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("add_preset")
                .font(.headline)
            
            TextField("preset_name", text: $presetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Spacer()
            
            HStack {
                Button("cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("save") {
                    if !presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave(presetName.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}


