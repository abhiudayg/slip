import SwiftUI
import UIKit

/// Slip design system — Stitch project 4563052560776738426 (Slip Wallet India).
/// Dark obsidian + glassmorphism; Inter-equivalent SF Pro + monospaced labels.
enum SlipTheme {
    /// mesh-base / primary-container
    static let canvasDeep = Color(hex: 0x070709)
    /// surface / background
    static let canvas = Color(hex: 0x141313)
    /// surface-container-lowest
    static let canvasLowest = Color(hex: 0x0E0E0E)
    /// surface-container
    static let card = Color(hex: 0x201F1F)
    /// surface-container-high
    static let cardHigh = Color(hex: 0x2B2A2A)
    /// surface-container-highest
    static let cardHighest = Color(hex: 0x353434)
    /// text-primary / on-surface
    static let ink = Color(hex: 0xF5F5F7)
    /// text-secondary
    static let muted = Color(hex: 0x8E8E93)
    /// on-surface-variant
    static let inkVariant = Color(hex: 0xC8C5CA)
    /// outline
    static let outline = Color(hex: 0x919095)
    /// outline-variant
    static let outlineVariant = Color(hex: 0x47464A)
    /// primary (silver)
    static let primary = Color(hex: 0xC8C6C8)
    /// Kept as accent for CTAs — soft silver-white (Stitch primary)
    static let accent = Color(hex: 0xC8C6C8)
    static let accentSoft = Color(hex: 0xE5E1E4)
    /// Brand accents used on pass shells (not DS primary)
    static let indigo = Color(hex: 0x3B82F6)
    static let magenta = Color(hex: 0xCC0050)
    static let upiGreen = Color(hex: 0x00F5A0)  // Stitch logo neon
    static let amber = Color(hex: 0xFF9F0A)
    static let secondary = Color(hex: 0xC7C5D0)
    /// tertiary / tertiary-fixed-dim
    static let tertiary = Color(hex: 0xCCC5BF)
    static let tertiaryDim = Color(hex: 0xCCC5BF)

    static let meshViolet = Color(hex: 0x1F1035)
    static let meshTeal = Color(hex: 0x0C2329)
    static let meshIndigo = Color(hex: 0x1F1035).opacity(0.55)
    static let meshBlue = Color(hex: 0x0C2329).opacity(0.45)
    static let meshMagenta = Color(hex: 0x46464F).opacity(0.35)

    static let glassSurface = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.12)

    /// Spacing (Stitch)
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let gutter: CGFloat = 16
        static let margin: CGFloat = 20
    }

    /// Flex-style layout tokens (prefer stacks/grids over absolute x/y).
    enum Layout {
        static let screenMargin: CGFloat = Space.margin
        static let sectionSpacing: CGFloat = 20
        static let dockClearance: CGFloat = 120
        /// Visible peek of each lower wallet card in the stacked list.
        static let walletStackPeek: CGFloat = 78
        static let walletCardMinHeight: CGFloat = 168
        static var walletStackOverlap: CGFloat { walletCardMinHeight - walletStackPeek }
    }

    static func color(fromRGB string: String?) -> Color? {
        guard let string,
              let inner = string.split(separator: "(").last?.split(separator: ")").first else { return nil }
        let parts = inner.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 3 else { return nil }
        return Color(red: parts[0] / 255, green: parts[1] / 255, blue: parts[2] / 255)
    }

    // MARK: Typography tokens (Inter → SF Pro; JetBrains Mono → monospaced)

    static func headlineXL() -> Font { .system(size: 34, weight: .bold) }
    static func headlineLG() -> Font { .system(size: 28, weight: .semibold) }
    static func headlineMD() -> Font { .system(size: 22, weight: .semibold) }
    static func headlineSM() -> Font { .system(size: 17, weight: .semibold) }
    static func bodyLG() -> Font { .system(size: 17, weight: .regular) }
    static func bodyMD() -> Font { .system(size: 15, weight: .regular) }
    static func bodySM() -> Font { .system(size: 13, weight: .regular) }
    static func labelMono() -> Font { .system(size: 12, weight: .medium, design: .monospaced) }
    static func codeMono() -> Font { .system(size: 15, weight: .semibold, design: .monospaced) }
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
    /// When true, draws the holographic double-frame motif from Stitch login.
    var holographicMotif: Bool = false

    var body: some View {
        SlipTheme.canvasLowest
            .ignoresSafeArea()
            .overlay(alignment: holographicMotif ? .top : .topLeading) {
                Circle()
                    .fill(SlipTheme.meshViolet.opacity(0.55))
                    .frame(width: 380, height: 380)
                    .blur(radius: 72)
                    .padding(holographicMotif ? .top : [.top, .leading], holographicMotif ? -120 : -80)
            }
            .overlay(alignment: holographicMotif ? .leading : .trailing) {
                Circle()
                    .fill(SlipTheme.meshTeal.opacity(holographicMotif ? 0.35 : 0.45))
                    .frame(width: 320, height: 320)
                    .blur(radius: 64)
                    .padding(holographicMotif ? .leading : .trailing, -60)
            }
            .overlay(alignment: holographicMotif ? .bottomTrailing : .bottom) {
                Circle()
                    .fill(Color(hex: holographicMotif ? 0x1F1035 : 0x46464F).opacity(holographicMotif ? 0.35 : 0.28))
                    .frame(width: 360, height: 360)
                    .blur(radius: 70)
                    .padding(.bottom, -40)
            }
            .overlay {
                if holographicMotif {
                    ZStack {
                        RoundedRectangle(cornerRadius: 48, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.03), lineWidth: 1)
                            .frame(width: 500, height: 500)
                            .rotationEffect(.degrees(12))
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.03), lineWidth: 1)
                            .frame(width: 460, height: 460)
                            .rotationEffect(.degrees(-6))
                    }
                    .allowsHitTesting(false)
                }
            }
            .overlay(SlipTheme.canvasLowest.opacity(0.55).allowsHitTesting(false))
            .ignoresSafeArea()
    }
}

/// Shared screen column — horizontal margin + dock clearance (flex column, not absolute coords).
struct SlipScreenColumn<Content: View>: View {
    var spacing: CGFloat = SlipTheme.Layout.sectionSpacing
    var includeDockClearance: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: spacing) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SlipTheme.Layout.screenMargin)
            .padding(.top, 8)
            .padding(.bottom, includeDockClearance ? SlipTheme.Layout.dockClearance : 24)
        }
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    var content: Content

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
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
                    .environment(\.colorScheme, .dark)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(SlipTheme.glassSurface)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.30), radius: 20, y: 10)
            }
    }
}

/// Precise Stitch physical ticket shell shape with left and right stub notches.
struct TicketCutoutShape: Shape {
    var cornerRadius: CGFloat = 16
    var cutoutRadius: CGFloat = 10
    var cutoutYFraction: CGFloat = 0.68

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cy = rect.height * cutoutYFraction
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: cy - cutoutRadius))
        path.addArc(center: CGPoint(x: rect.maxX, y: cy),
                    radius: cutoutRadius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: cy + cutoutRadius))
        path.addArc(center: CGPoint(x: rect.minX, y: cy),
                    radius: cutoutRadius, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct StatusPill: View {
    var title: String
    var tint: Color = SlipTheme.upiGreen
    var filled: Bool = false
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
            } else {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                    .shadow(color: tint.opacity(0.8), radius: 4)
            }
            Text(title)
                .font(SlipTheme.labelMono())
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(filled ? SlipTheme.canvasDeep : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(filled ? Color.white.opacity(0.95) : tint.opacity(0.15))
        )
        .overlay(
            Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.30), lineWidth: 1)
        )
    }
}

/// Stitch top chrome — greeting left, glass icon right (notifications).
struct StudioTopBar<Avatar: View>: View {
    var title: String
    var subtitle: String? = nil
    var onSearch: (() -> Void)? = nil
    var avatar: Avatar

    init(title: String, subtitle: String? = nil, onSearch: (() -> Void)? = nil, @ViewBuilder avatar: () -> Avatar) {
        self.title = title
        self.subtitle = subtitle
        self.onSearch = onSearch
        self.avatar = avatar()
    }

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SlipTheme.headlineSM())
                    .tracking(-0.2)
                    .foregroundStyle(SlipTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                        .tracking(0.6)
                }
            }
            Spacer(minLength: 8)
            if let onSearch {
                Button(action: onSearch) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(SlipTheme.card.opacity(0.7)))
                        .overlay(Circle().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(Color(hex: 0x818CF8))
                                .frame(width: 8, height: 8)
                                .padding(8)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension StudioTopBar where Avatar == EmptyView {
    init(title: String, subtitle: String? = nil, onSearch: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onSearch: onSearch) { EmptyView() }
    }
}

/// App brand mark from Assets.xcassets/SlipLogo (Stitch slip_wallet_app_icon_logo).
struct SlipBrandMark: View {
    var size: CGFloat = 28
    var glow: Bool = false

    var body: some View {
        Image("SlipLogo")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .strokeBorder(SlipTheme.glassBorder, lineWidth: glow ? 1 : 0)
            )
            .background {
                if glow {
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    SlipTheme.meshViolet.opacity(0.55),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size + 20, height: size + 20)
                        .blur(radius: 18)
                }
            }
            .shadow(color: glow ? SlipTheme.meshViolet.opacity(0.55) : .clear, radius: glow ? 24 : 0, y: glow ? 8 : 0)
            .accessibilityLabel("Slip")
    }
}

/// Profile photo or monogram. Apple Sign In never supplies a photo, so monogram is the default.
struct ProfileAvatarView: View {
    var image: UIImage?
    var monogram: String
    var size: CGFloat = 54
    var showOnlineDot: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x3B82F6), Color(hex: 0x1F1035)],
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
                    .strokeBorder(
                        LinearGradient(
                            colors: [SlipTheme.primary.opacity(0.4), SlipTheme.glassBorder],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            if showOnlineDot {
                Circle()
                    .fill(SlipTheme.upiGreen)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(Circle().strokeBorder(SlipTheme.canvasLowest, lineWidth: 2))
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(image == nil ? "Profile monogram \(monogram)" : "Profile photo")
    }
}

/// Stitch FloatingDock — home · scan · explore · settings (pill glass capsule).
struct FloatingDock: View {
    enum Tab: Hashable {
        case home, marketplace, settings
    }

    @Binding var tab: Tab
    var onScan: () -> Void
    var onNewPass: () -> Void
    var onImport: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            dockIcon("house.fill", selected: tab == .home) { tab = .home }
            dockIcon("doc.viewfinder", selected: false) {
                if let onImport {
                    onImport()
                } else {
                    onScan()
                }
            }
            dockIcon("safari.fill", selected: tab == .marketplace) { tab = .marketplace }
            dockIcon("gearshape", selected: tab == .settings) { tab = .settings }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: 320)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(Capsule().fill(SlipTheme.cardHigh.opacity(0.70)))
                .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                .shadow(color: .black.opacity(0.60), radius: 20, y: 10)
        }
        .frame(maxWidth: .infinity) // center capsule in the safe-area inset
        .contextMenu {
            Button("New Pass", systemImage: "plus") { onNewPass() }
            Button("Scan", systemImage: "qrcode.viewfinder") { onScan() }
        }
    }

    private func dockIcon(
        _ systemName: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selected ? SlipTheme.canvasLowest : SlipTheme.muted)
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(selected ? SlipTheme.primary : Color.clear)
                )
                .shadow(color: selected ? SlipTheme.primary.opacity(0.25) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(systemName)
        .accessibilityLabel(systemName)
        .frame(maxWidth: .infinity) // equal flex hit-targets; icon stays 48pt centered
    }
}


/// Brightness helpers that avoid deprecated `UIScreen.main` (iOS 26+).
enum ScreenBrightness {
    static var current: CGFloat {
        activeScreen?.brightness ?? 1
    }

    static func set(_ value: CGFloat) {
        activeScreen?.brightness = value
    }

    private static var activeScreen: UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let key = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.windowScene?.screen {
            return key
        }
        return scenes.first?.screen
    }
}
