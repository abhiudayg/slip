import SwiftUI

/// Liquid Glass Pass Engine tokens (Stitch design system).
enum SlipTheme {
    static let canvas = Color(hex: 0x11121E)
    static let canvasDeep = Color(hex: 0x080914)
    static let card = Color(hex: 0x1E1F2B)
    static let cardHigh = Color(hex: 0x282935)
    static let ink = Color(hex: 0xE2E1F2)
    static let muted = Color(hex: 0xC0C6D6)
    static let outline = Color(hex: 0x414754)
    static let accent = Color(hex: 0x0A84FF)
    static let accentSoft = Color(hex: 0xAAC7FF)
    static let indigo = Color(hex: 0x5E5CE6)
    static let magenta = Color(hex: 0xFF2D55)
    static let upiGreen = Color(hex: 0x30D158)
    static let amber = Color(hex: 0xFF9F0A)

    static let meshIndigo = Color(hex: 0x5E5CE6).opacity(0.35)
    static let meshBlue = Color(hex: 0x0A84FF).opacity(0.28)
    static let meshMagenta = Color(hex: 0xFF2D55).opacity(0.22)

    static func color(fromRGB string: String?) -> Color? {
        guard let string,
              let inner = string.split(separator: "(").last?.split(separator: ")").first else { return nil }
        let parts = inner.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 3 else { return nil }
        return Color(red: parts[0] / 255, green: parts[1] / 255, blue: parts[2] / 255)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

struct MeshBackground: View {
    var body: some View {
        ZStack {
            SlipTheme.canvasDeep
            RadialGradient(
                colors: [SlipTheme.meshIndigo, .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
            RadialGradient(
                colors: [SlipTheme.meshBlue, .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 280
            )
            RadialGradient(
                colors: [SlipTheme.meshMagenta, .clear],
                center: UnitPoint(x: 0.4, y: 0.85),
                startRadius: 10,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 16
    var content: Content

    init(cornerRadius: CGFloat = 24, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.32),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
            }
    }
}

struct StatusPill: View {
    var title: String
    var tint: Color = SlipTheme.accent
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
                .shadow(color: tint.opacity(0.8), radius: 4)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(filled ? SlipTheme.canvasDeep : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(filled ? Color.white.opacity(0.95) : tint.opacity(0.15))
        )
    }
}

/// App brand mark from Assets.xcassets/SlipLogo
struct SlipBrandMark: View {
    var size: CGFloat = 28

    var body: some View {
        Image("SlipLogo")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .accessibilityLabel("Slip")
    }
}

struct FloatingDock: View {
    enum Tab: Hashable {
        case home, marketplace, settings
    }

    @Binding var tab: Tab
    var onCamera: () -> Void
    var onScan: () -> Void
    var onNewPass: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            dockIcon("camera.fill", selected: false, action: onCamera)
            Button(action: onNewPass) {
                Label("New Pass", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.black))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
            dockIcon("qrcode.viewfinder", selected: false, action: onScan)
            dockIcon(
                "slider.horizontal.3",
                selected: tab == .settings,
                action: { tab = .settings }
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
        }
    }

    private func dockIcon(_ systemName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selected ? SlipTheme.accentSoft : .white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(selected ? SlipTheme.accent.opacity(0.2) : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}
