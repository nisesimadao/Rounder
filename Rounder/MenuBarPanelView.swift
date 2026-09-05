//
//  MenuBarPanelView.swift
//  Rounder
//
//  Compact SwiftUI controls hosted inside the real NSMenu owned by
//  MenuBarController. UserDefaults remain the durable source of truth; the
//  callbacks only perform runtime side effects for direct panel interactions.
//

import SwiftUI

struct MenuBarPanelView: View {
    @AppStorage(UserDefaultsKeys.isEnabled) private var isEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.cornerRadius) private var cornerRadius: Double = RounderAppConstants.defaultCornerRadius
    @AppStorage(UserDefaultsKeys.cornerCutoutStyle) private var cornerCutoutStyleRawValue: String = CornerCutoutStyle.rounded.rawValue

    let onEnabledChanged: (Bool) -> Void
    let onGeometryChanged: (Double, CornerCutoutStyle) -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    private var cutoutStyle: CornerCutoutStyle {
        CornerCutoutStyle(rawValue: cornerCutoutStyleRawValue) ?? .rounded
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                guard newValue != isEnabled else { return }
                isEnabled = newValue
                onEnabledChanged(newValue)
            }
        )
    }

    private var radiusBinding: Binding<Double> {
        Binding(
            get: { cornerRadius },
            set: { newValue in
                let snapped = min(
                    max(newValue.rounded(), RounderAppConstants.cornerRadiusMin),
                    RounderAppConstants.cornerRadiusMax
                )
                guard snapped != cornerRadius else { return }
                cornerRadius = snapped
                onGeometryChanged(snapped, cutoutStyle)
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                enableRow
                radiusSection
                shapeSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()
            footer
        }
        .frame(width: 280)
    }

    private var enableRow: some View {
        HStack(spacing: 10) {
            Text("enable_rounded_corners")
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 8)
            Toggle("", isOn: enabledBinding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("corner_radius")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("\(Int(cornerRadius)) px")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 34, alignment: .trailing)
            }

            Slider(
                value: radiusBinding,
                in: RounderAppConstants.cornerRadiusMin...RounderAppConstants.cornerRadiusMax,
                step: RounderAppConstants.cornerRadiusStep
            )
            .accessibilityLabel(Text("corner_radius"))
            .accessibilityValue(Text("\(Int(cornerRadius)) px"))
        }
    }

    private var shapeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("corner_shape")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(CornerCutoutStyle.allCases) { style in
                    CornerShapeButton(
                        style: style,
                        isSelected: style == cutoutStyle
                    ) {
                        selectStyle(style)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 0) {
            PanelFooterButton(systemImage: "gearshape", title: String(localized: "settings_menu")) {
                onOpenSettings()
            }

            Spacer(minLength: 8)

            PanelFooterButton(systemImage: "power", title: String(localized: "quit_menu")) {
                onQuit()
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
    }

    private func selectStyle(_ style: CornerCutoutStyle) {
        guard style != cutoutStyle else { return }
        cornerCutoutStyleRawValue = style.rawValue
        onGeometryChanged(cornerRadius, style)
    }
}

private struct CornerShapeButton: View {
    let style: CornerCutoutStyle
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            CornerShapePreview(style: style)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(backgroundStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(style.localizedDisplayName)
        .accessibilityLabel(Text(style.localizedDisplayName))
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
        } else if isHovered {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        } else {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        }
    }
}

/// A normalized preview of the same geometry used by the real corner overlay.
/// It deliberately does not use the user's current radius: at Radius=0 the
/// shape picker still has to explain the three available shape families.
private struct CornerShapePreview: View {
    let style: CornerCutoutStyle

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height, 24)
            let bounds = CGRect(
                x: (size.width - side) / 2,
                y: (size.height - side) / 2,
                width: side,
                height: side
            )

            let path = CGMutablePath()
            switch style {
            case .rounded:
                path.addRect(bounds)
                path.addPath(
                    CornerGeometry.roundedCutoutPath(
                        in: bounds,
                        radius: side,
                        cornerType: .topLeft
                    )
                )
            case .squircle:
                path.addRect(bounds)
                path.addPath(
                    CornerGeometry.squircleCutoutPath(
                        in: bounds,
                        cornerType: .topLeft
                    )
                )
            case .polygon:
                path.addPath(
                    CornerGeometry.polygonMaskPath(
                        in: bounds,
                        radius: side,
                        cornerType: .topLeft
                    )
                )
            }

            context.fill(
                Path(path),
                with: .color(.primary),
                style: FillStyle(eoFill: true, antialiased: true)
            )
        }
        .accessibilityHidden(true)
    }
}

private struct PanelFooterButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
