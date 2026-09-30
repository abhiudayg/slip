import SwiftUI

/// Liquid Glass Pass Engine tokens (Stitch design system — project 6057453755376154551).
enum SlipTheme {
    /// surface / surface-container
    static let canvas = Color(hex: 0x0B0E18)
    static let canvasDeep = Color(hex: 0x070913)
    static let card = Color(hex: 0x191B26)
    static let cardHigh = Color(hex: 0x272935)
    /// on-surface / on-surface-variant
    static let ink = Color(hex: 0xE1E1F1)
    static let muted = Color(hex: 0xCCC3D8)
    static let outline = Color(hex: 0x4A4455)
    /// Stitch primary = violet
    static let accent = Color(hex: 0x7C3AED)
    static let accentSoft = Color(hex: 0xD2BBFF)
    static let indigo = Color(hex: 0x732EE4)
    static let magenta = Color(hex: 0xCC0050)
    static let upiGreen = Color(hex: 0x30D158)
    static let amber = Color(hex: 0xFF9F0A)
    /// secondary cyan used on lock-screen labels
    static let secondary = Color(hex: 0x93CCFF)

    static let meshIndigo = Color(hex: 0x7C3AED).opacity(0.38)
    static let meshBlue = Color(hex: 0x93CCFF).opacity(0.22)
    static let meshMagenta = Color(hex: 0xCC0050).opacity(0.18)

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
    var tint: Color = SlipTheme.accentSoft
    var filled: Bool = false
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
            } else {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .shadow(color: tint.opacity(0.8), radius: 4)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
        }
        .foregroundStyle(filled ? SlipTheme.canvasDeep : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(filled ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
        )
        .overlay(
            Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.35), lineWidth: 1)
        )
    }
}

/// Stitch top chrome: brand mark + title · search · avatar
struct StudioTopBar<Avatar: View>: View {
    var title: String
    var onSearch: (() -> Void)? = nil
    var avatar: Avatar

    init(title: String, onSearch: (() -> Void)? = nil, @ViewBuilder avatar: () -> Avatar) {
        self.title = title
        self.onSearch = onSearch
        self.avatar = avatar()
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(SlipTheme.accent.opacity(0.22))
                        .frame(width: 36, height: 36)
                    SlipBrandMark(size: 22)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(SlipTheme.ink)
            }
            Spacer(minLength: 8)
            if let onSearch {
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.04)))
                }
                .buttonStyle(.plain)
            }
            avatar
        }
    }
}

extension StudioTopBar where Avatar == EmptyView {
    init(title: String, onSearch: (() -> Void)? = nil) {
        self.init(title: title, onSearch: onSearch) { EmptyView() }
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

/// Profile photo or monogram. Apple Sign In never supplies a photo, so monogram is the default.
struct ProfileAvatarView: View {
    var image: UIImage?
    var monogram: String
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SlipTheme.indigo, SlipTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(monogram.isEmpty ? "S" : monogram)
                    .font(.system(size: size * (monogram.count > 1 ? 0.32 : 0.4), weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
        .accessibilityLabel(image == nil ? "Profile monogram \(monogram)" : "Profile photo")
    }
}

struct FloatingDock: View {
    enum Tab: Hashable {
        case home, marketplace, settings
    }

    @Binding var tab: Tab
    var onScan: () -> Void
    var onNewPass: () -> Void
    /// Stitch left dock action (camera / import). When off home, becomes Home.
    var onImport: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            dockIcon(
                tab == .home ? "camera.fill" : "house.fill",
                selected: tab != .home,
                tint: tab == .home ? SlipTheme.muted : SlipTheme.accentSoft,
                action: {
                    if tab == .home, let onImport {
                        onImport()
                    } else {
                        tab = .home
                    }
                }
            )
            Button(action: onNewPass) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SlipTheme.accentSoft)
                    Text("New Pass")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.2)
                        .foregroundStyle(SlipTheme.ink)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            dockIcon("qrcode.viewfinder", selected: false, tint: SlipTheme.muted, action: onScan)
            dockIcon(
                "slider.horizontal.3",
                selected: tab == .settings,
                tint: tab == .settings ? SlipTheme.accentSoft : SlipTheme.muted,
                action: { tab = .settings }
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(Capsule().fill(SlipTheme.cardHigh.opacity(0.45)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 10)
        }
    }

    private func dockIcon(
        _ systemName: String,
        selected: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selected ? SlipTheme.accentSoft : tint)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(selected ? SlipTheme.accent.opacity(0.22) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
