//
//  MenuBarPanelView.swift
//  Rounder
//
//  Compact SwiftUI controls hosted inside the real NSMenu owned by
//  MenuBarController. UserDefaults remain the durable source of truth; the
//  callbacks only perform runtime side effects for direct panel interactions.
//

import AppKit
import SwiftUI

struct MenuBarPanelView: View {
    @AppStorage(UserDefaultsKeys.isEnabled) private var isEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.cornerRadius) private var cornerRadius: Double = RounderAppConstants.defaultCornerRadius
    @AppStorage(UserDefaultsKeys.cornerCutoutStyle) private var cornerCutoutStyleRawValue: String = CornerCutoutStyle.rounded.rawValue
    @AppStorage(UserDefaultsKeys.cornerColor) private var cornerColorData: Data = Data()
    @AppStorage(UserDefaultsKeys.topLeftEnabled) private var topLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.topRightEnabled) private var topRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomLeftEnabled) private var bottomLeftEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.bottomRightEnabled) private var bottomRightEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.superGamingMode) private var superGamingMode: Bool = false

    let onEnabledChanged: (Bool) -> Void
    let onGeometryChanged: (Double, CornerCutoutStyle) -> Void
    let onColorChanged: (NSColor) -> Void
    let onOverlayStructureChanged: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    private var cutoutStyle: CornerCutoutStyle {
        CornerCutoutStyle(rawValue: cornerCutoutStyleRawValue) ?? .rounded
    }

    private var cornerNSColor: NSColor {
        guard !cornerColorData.isEmpty,
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: cornerColorData) else {
            return .black
        }
        return color
    }

    private var cornerSwiftUIColor: Color {
        Color(cornerNSColor)
    }

    private let quickColors: [NSColor] = [.black, .white, .systemGray]

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                guard newValue != isEnabled else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    isEnabled = newValue
                }
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

    private var gamingBinding: Binding<Bool> {
        Binding(
            get: { superGamingMode },
            set: { newValue in
                guard newValue != superGamingMode else { return }
                withAnimation(.snappy(duration: 0.2)) {
                    superGamingMode = newValue
                }
                onOverlayStructureChanged()
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                enableRow
                sectionDivider
                radiusSection
                sectionDivider
                shapeSection
                sectionDivider
                colorSection
                sectionDivider
                cornersSection
                sectionDivider
                gamingRow
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()
            footer
        }
        .frame(width: 300)
    }

    private var sectionDivider: some View {
        Divider()
            .opacity(0.65)
    }

    private var enableRow: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(isEnabled ? Color.green : Color.secondary.opacity(0.45))
                .frame(width: 7, height: 7)
                .scaleEffect(isEnabled ? 1 : 0.8)
                .animation(.snappy(duration: 0.18), value: isEnabled)

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
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 8)
                Text("\(Int(cornerRadius)) px")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.1), value: cornerRadius)
                    .frame(minWidth: 38, alignment: .trailing)
            }

            Slider(
                value: radiusBinding,
                in: RounderAppConstants.cornerRadiusMin...RounderAppConstants.cornerRadiusMax,
                step: RounderAppConstants.cornerRadiusStep
            )
            .tint(.accentColor)
            .accessibilityLabel(Text("corner_radius"))
            .accessibilityValue(Text("\(Int(cornerRadius)) px"))
        }
    }

    private var shapeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("corner_shape")
                .font(.system(size: 12, weight: .medium))

            HStack(spacing: 7) {
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

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("corner_color")
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 8)

                Circle()
                    .fill(cornerSwiftUIColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.22), lineWidth: 0.6)
                    )
                    .shadow(color: Color.primary.opacity(0.08), radius: 1, y: 1)
            }

            HStack(spacing: 9) {
                ForEach(Array(quickColors.enumerated()), id: \.offset) { _, color in
                    ColorSwatchButton(
                        color: color,
                        isSelected: colorsMatch(cornerNSColor, color)
                    ) {
                        selectColor(color)
                    }
                }

                Spacer(minLength: 8)

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 27, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.055))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("corner_color"))
            }
        }
    }

    private var cornersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("pane_corners")
                .font(.system(size: 12, weight: .medium))

            HStack(spacing: 7) {
                ForEach(Array(ScreenCorner.allCases.enumerated()), id: \.offset) { _, corner in
                    CornerToggleButton(
                        corner: corner,
                        isEnabled: isCornerEnabled(corner)
                    ) {
                        toggleCorner(corner)
                    }
                }
            }
        }
    }

    private var gamingRow: some View {
        HStack(spacing: 9) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(superGamingMode ? Color.accentColor : Color.secondary)
                .rotationEffect(.degrees(superGamingMode ? 5 : 0))
                .scaleEffect(superGamingMode ? 1.08 : 1)
                .animation(.snappy(duration: 0.2), value: superGamingMode)

            Text("super_gaming_mode")
                .font(.system(size: 12, weight: .medium))

            Spacer(minLength: 8)

            Toggle("", isOn: gamingBinding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
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
        .frame(height: 34)
    }

    private func selectStyle(_ style: CornerCutoutStyle) {
        guard cornerCutoutStyleRawValue != style.rawValue else { return }
        withAnimation(.snappy(duration: 0.18)) {
            cornerCutoutStyleRawValue = style.rawValue
        }
        onGeometryChanged(cornerRadius, style)
    }

    private func selectColor(_ color: NSColor) {
        guard !colorsMatch(cornerNSColor, color),
              let data = try? NSKeyedArchiver.archivedData(
                withRootObject: color,
                requiringSecureCoding: true
              ) else {
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            cornerColorData = data
        }
        onColorChanged(color)
    }

    private func isCornerEnabled(_ corner: ScreenCorner) -> Bool {
        switch corner {
        case .topLeft: return topLeftEnabled
        case .topRight: return topRightEnabled
        case .bottomLeft: return bottomLeftEnabled
        case .bottomRight: return bottomRightEnabled
        }
    }

    private func toggleCorner(_ corner: ScreenCorner) {
        withAnimation(.snappy(duration: 0.18)) {
            switch corner {
            case .topLeft: topLeftEnabled.toggle()
            case .topRight: topRightEnabled.toggle()
            case .bottomLeft: bottomLeftEnabled.toggle()
            case .bottomRight: bottomRightEnabled.toggle()
            }
        }
        onOverlayStructureChanged()
    }

    private func colorsMatch(_ lhs: NSColor, _ rhs: NSColor) -> Bool {
        guard let a = lhs.usingColorSpace(.sRGB),
              let b = rhs.usingColorSpace(.sRGB) else {
            return lhs.isEqual(rhs)
        }

        let tolerance: CGFloat = 0.01
        return abs(a.redComponent - b.redComponent) < tolerance &&
               abs(a.greenComponent - b.greenComponent) < tolerance &&
               abs(a.blueComponent - b.blueComponent) < tolerance &&
               abs(a.alphaComponent - b.alphaComponent) < tolerance
    }
}

private struct CornerShapeButton: View {
    let style: CornerCutoutStyle
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            CornerShapePreview(
                style: style,
                fillColor: isSelected ? .accentColor : .secondary
            )
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(backgroundStyle)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.09),
                        lineWidth: isSelected ? 1.4 : 0.6
                    )
            )
            .scaleEffect(isSelected ? 1 : (isHovered ? 0.99 : 0.975))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(Text(style.localizedDisplayName))
        .animation(.snappy(duration: 0.18), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.accentColor.opacity(0.13))
        } else if isHovered {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.075))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }
}

/// A normalized preview of the same visible quadrant used by the real overlay.
/// The production rounded mask clears a full circle and relies on the NSView's
/// bounds to clip the three invisible quarters. A Canvas has extra room around
/// this sample, so drawing that full circle leaks the normally-clipped area into
/// the menu. Using the bounded quadrant path is visually equivalent on-screen
/// and never draws outside the preview tile.
private struct CornerShapePreview: View {
    let style: CornerCutoutStyle
    let fillColor: Color

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height, 25)
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
                    CornerGeometry.roundedQuadrantPath(
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
                with: .color(fillColor),
                style: FillStyle(eoFill: true, antialiased: true)
            )
        }
        .accessibilityHidden(true)
    }
}

private struct ColorSwatchButton: View {
    let color: NSColor
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(color))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.25), lineWidth: 0.7)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
                        .padding(-3)
                )
                .scaleEffect(isSelected ? 1.06 : (isHovered ? 1.03 : 1))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.snappy(duration: 0.16), value: isSelected)
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

private struct CornerToggleButton: View {
    let corner: ScreenCorner
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var dotAlignment: Alignment {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    private var accessibilityName: String {
        switch corner {
        case .topLeft: return String(localized: "top_left_corner")
        case .topRight: return String(localized: "top_right_corner")
        case .bottomLeft: return String(localized: "bottom_left_corner")
        case .bottomRight: return String(localized: "bottom_right_corner")
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: dotAlignment) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        isEnabled ? Color.accentColor.opacity(0.72) : Color.secondary.opacity(0.38),
                        lineWidth: isEnabled ? 1.2 : 0.8
                    )

                Circle()
                    .fill(isEnabled ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        isEnabled
                            ? Color.accentColor.opacity(0.105)
                            : (isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.025))
                    )
            )
            .scaleEffect(isEnabled ? 1 : 0.97)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(Text(accessibilityName))
        .accessibilityValue(Text(isEnabled ? "On" : "Off"))
        .animation(.snappy(duration: 0.18), value: isEnabled)
        .animation(.easeOut(duration: 0.1), value: isHovered)
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
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}
