import SwiftUI

extension Color {
    static let atriaInk = Color(hex: "171717")
    static let atriaIvory = Color(hex: "F7F1E8")
    static let atriaPaper = Color(hex: "FFF9F0")
    static let atriaCopper = Color(hex: "A96843")
    static let atriaSage = Color(hex: "A9B9B1")
    static let atriaBlue = Color(hex: "556878")

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

struct AtriaBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "F8F2EA"),
                Color(hex: "EAF0EC"),
                Color(hex: "F6EEE3")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GlassPanel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.74), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 12)
    }
}

struct AtriaButton: View {
    var title: String
    var systemImage: String
    var style: Style = .primary
    var action: () -> Void

    enum Style {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(style == .primary ? Color.white : Color.atriaInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var background: some ShapeStyle {
        style == .primary ? AnyShapeStyle(Color.atriaInk) : AnyShapeStyle(Color.white.opacity(0.7))
    }
}

struct MetricPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.atriaCopper)
                .frame(width: 28, height: 28)
                .background(Color.atriaCopper.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.atriaInk)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
