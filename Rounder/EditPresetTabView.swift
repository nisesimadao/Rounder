//
//  EditPresetTabView.swift
//  Rounder
//
//  Created by Nisesimadao on 2026/04/25.
//

import SwiftUI

struct EditPresetTabView: View {
    @Binding var preset: CornerPreset
    @State private var tempName: String
    @State private var tempRadius: Double
    @State private var tempColor: Color
    @State private var tempTopLeftEnabled: Bool
    @State private var tempTopRightEnabled: Bool
    @State private var tempBottomLeftEnabled: Bool
    @State private var tempBottomRightEnabled: Bool
    @State private var tempSuperGamingMode: Bool
    @State private var tempGamingSpeed: Double
    @State private var hasUnsavedChanges: Bool = false
    
    let onSave: (CornerPreset) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(preset: Binding<CornerPreset>, onSave: @escaping (CornerPreset) -> Void, onCancel: @escaping () -> Void) {
        self._preset = preset
        self.onSave = onSave
        self.onCancel = onCancel
        
        // 初期値を設定
        let initialPreset = preset.wrappedValue
        self._tempName = State(initialValue: initialPreset.name)
        self._tempRadius = State(initialValue: initialPreset.cornerRadius)
        self._tempColor = State(initialValue: initialPreset.cornerSwiftUIColor)
        self._tempTopLeftEnabled = State(initialValue: initialPreset.topLeftEnabled)
        self._tempTopRightEnabled = State(initialValue: initialPreset.topRightEnabled)
        self._tempBottomLeftEnabled = State(initialValue: initialPreset.bottomLeftEnabled)
        self._tempBottomRightEnabled = State(initialValue: initialPreset.bottomRightEnabled)
        self._tempSuperGamingMode = State(initialValue: initialPreset.superGamingMode)
        self._tempGamingSpeed = State(initialValue: initialPreset.gamingSpeed)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("edit_preset")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("cancel") {
                        onCancel()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("save") {
                        savePreset()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasUnsavedChanges)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 設定内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // プリセット名
                    VStack(alignment: .leading, spacing: 8) {
                        Text("preset_name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("preset_name", text: $tempName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: tempName) { _, _ in
                                markAsChanged()
                            }
                    }
                    
                    // 角の表示設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("corner_visibility")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 8) {
                            // 上段
                            HStack(spacing: 20) {
                                Toggle("top_left_corner", isOn: $tempTopLeftEnabled)
                                    .onChange(of: tempTopLeftEnabled) { _, _ in
                                        markAsChanged()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Toggle("top_right_corner", isOn: $tempTopRightEnabled)
                                    .onChange(of: tempTopRightEnabled) { _, _ in
                                        markAsChanged()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // 下段
                            HStack(spacing: 20) {
                                Toggle("bottom_left_corner", isOn: $tempBottomLeftEnabled)
                                    .onChange(of: tempBottomLeftEnabled) { _, _ in
                                        markAsChanged()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Toggle("bottom_right_corner", isOn: $tempBottomRightEnabled)
                                    .onChange(of: tempBottomRightEnabled) { _, _ in
                                        markAsChanged()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    // 角の半径
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("corner_radius")
                            Spacer()
                            Text("\(Int(tempRadius))px")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        
                        Slider(value: $tempRadius, in: 0...40, step: 1)
                            .onChange(of: tempRadius) { _, _ in
                                markAsChanged()
                            }
                    }
                    
                    // 色選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("corner_color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            ColorPicker("", selection: $tempColor)
                                .labelsHidden()
                                .onChange(of: tempColor) { _, _ in
                                    markAsChanged()
                                }
                            
                            Text("custom_color")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // すーぱーげーみんぐもーど
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("super_gaming_mode", isOn: $tempSuperGamingMode)
                                .onChange(of: tempSuperGamingMode) { _, _ in
                                    markAsChanged()
                                }
                        }
                        
                        if tempSuperGamingMode {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("gaming_speed")
                                    Spacer()
                                    Text(String(format: "%.1fx", tempGamingSpeed))
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                
                                Slider(value: $tempGamingSpeed, in: 0.1...5.0, step: 0.1)
                                    .onChange(of: tempGamingSpeed) { _, _ in
                                        markAsChanged()
                                    }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func markAsChanged() {
        hasUnsavedChanges = true
    }
    
    private func savePreset() {
        var updatedPreset = preset
        updatedPreset = updatedPreset.withName(tempName)
        updatedPreset = updatedPreset.withRadius(tempRadius)
        updatedPreset = updatedPreset.withColor(NSColor(tempColor))
        updatedPreset = updatedPreset.withCorners(
            topLeft: tempTopLeftEnabled,
            topRight: tempTopRightEnabled,
            bottomLeft: tempBottomLeftEnabled,
            bottomRight: tempBottomRightEnabled
        )
        updatedPreset = updatedPreset.withGamingMode(tempSuperGamingMode, speed: tempGamingSpeed)
        
        onSave(updatedPreset)
        dismiss()
    }
}

// CornerPresetの拡張
extension CornerPreset {
    func withName(_ name: String) -> CornerPreset {
        var updated = self
        updated.name = name
        return updated
    }
    
    func withRadius(_ radius: Double) -> CornerPreset {
        var updated = self
        updated.cornerRadius = radius
        return updated
    }
    
    func withColor(_ color: NSColor) -> CornerPreset {
        var updated = self
        updated.cornerColor = try! NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        return updated
    }
    
    func withCorners(topLeft: Bool, topRight: Bool, bottomLeft: Bool, bottomRight: Bool) -> CornerPreset {
        var updated = self
        updated.topLeftEnabled = topLeft
        updated.topRightEnabled = topRight
        updated.bottomLeftEnabled = bottomLeft
        updated.bottomRightEnabled = bottomRight
        return updated
    }
    
    func withGamingMode(_ enabled: Bool, speed: Double) -> CornerPreset {
        var updated = self
        updated.superGamingMode = enabled
        updated.gamingSpeed = speed
        return updated
    }
}

#Preview {
    EditPresetTabView(
        preset: .constant(CornerPreset(name: "Test Preset")),
        onSave: { _ in },
        onCancel: { }
    )
}
