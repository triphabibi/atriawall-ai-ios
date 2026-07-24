import SwiftUI

// MARK: - Palette

extension Color {
    static let atriaInk = Color(hex: "1A1714")
    static let atriaInkSoft = Color(hex: "4A423B")
    static let atriaIvory = Color(hex: "F7F1E8")
    static let atriaPaper = Color(hex: "FFF9F0")
    static let atriaCopper = Color(hex: "A96843")
    static let atriaCopperDeep = Color(hex: "8A5232")
    static let atriaSage = Color(hex: "A9B9B1")
    static let atriaBlue = Color(hex: "556878")
    static let atriaLine = Color(hex: "1A1714").opacity(0.08)

    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch clean.count {
        case 6:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        default:
            red = 0x22
            green = 0x22
            blue = 0x22
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

// MARK: - Spacing & radius tokens

enum Metrics {
    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 18
    static let radiusLarge: CGFloat = 26
    static let gap: CGFloat = 14
    static let inset: CGFloat = 16
}

// MARK: - Background

struct AtriaBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "F8F2EA"),
                    Color(hex: "EEF1EC"),
                    Color(hex: "F6EEE3")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.5), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Cards

struct GlassPanel<Content: View>: View {
    var padding: CGFloat = Metrics.inset
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: Metrics.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusMedium, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 22, x: 0, y: 14)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.atriaCopper)
                    .frame(width: 30, height: 30)
                    .background(Color.atriaCopper.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.atriaInk)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Buttons

struct AtriaButton: View {
    var title: String
    var systemImage: String
    var style: Style = .primary
    var isLoading: Bool = false
    var action: () -> Void

    enum Style {
        case primary
        case secondary
        case copper
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background, in: RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
            .shadow(color: shadowColor, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary, .copper: return .white
        case .secondary: return .atriaInk
        }
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary: return AnyShapeStyle(Color.atriaInk)
        case .copper: return AnyShapeStyle(LinearGradient(colors: [Color.atriaCopper, Color.atriaCopperDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .secondary: return AnyShapeStyle(Color.white.opacity(0.7))
        }
    }

    private var borderColor: Color {
        style == .secondary ? Color.atriaInk.opacity(0.14) : .clear
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return Color.atriaInk.opacity(0.22)
        case .copper: return Color.atriaCopper.opacity(0.32)
        case .secondary: return .black.opacity(0.05)
        }
    }
}

// MARK: - Metric pill

struct MetricPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.atriaCopper)
                .frame(width: 30, height: 30)
                .background(Color.atriaCopper.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.atriaInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous))
    }
}

// MARK: - Tag / chip

struct AtriaTag: View {
    var text: String
    var systemImage: String?
    var tint: Color = .atriaCopper

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

// MARK: - Empty state

struct EmptyStatePanel: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.atriaCopper)
                .frame(width: 84, height: 84)
                .background(Color.atriaCopper.opacity(0.10), in: Circle())

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.atriaInk)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                AtriaButton(title: actionTitle, systemImage: "plus", style: .copper, action: action)
                    .padding(.top, 4)
                    .padding(.horizontal, 30)
            }
        }
        .padding(26)
    }
}
