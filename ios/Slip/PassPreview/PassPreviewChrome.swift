import SwiftUI


struct PassShimmerOverlay: View {
    var body: some View { PassMotionShimmerOverlay() }
}

struct PassShell<Content: View>: View {
    let palette: PassPalette
    var appIcon: String? = nil
    @ViewBuilder var content: Content
    @ObservedObject private var motion = PassMotionGlow.shared

    var body: some View {
        let ox = motion.active ? motion.roll * 14 : 0
        let oy = motion.active ? 16 + motion.pitch * 10 : 16
        content
            .background(
                LinearGradient(colors: [palette.top, palette.mid, palette.bottom], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), SlipTheme.glassBorder, Color.white.opacity(0.06)],
                            startPoint: UnitPoint(x: 0.2 + motion.roll * 0.15, y: 0),
                            endPoint: UnitPoint(x: 0.85 - motion.roll * 0.1, y: 1)
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .bottomLeading) {
                if let appIcon {
                    Image(systemName: appIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(20)
                }
            }
            .overlay {
                PassMotionShimmerOverlay()
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .allowsHitTesting(false)
            }
            .shadow(color: palette.glow.opacity(0.85), radius: 28, x: ox, y: oy)
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: ox * 0.5, y: 10 + oy * 0.15)
            .onAppear { motion.retain() }
            .onDisappear { motion.release() }
    }
}

struct EventTicketShape: InsettableShape {
    var notchRadius: CGFloat = 16
    var cornerRadius: CGFloat = 26
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        
        path.move(to: CGPoint(x: r.minX + cornerRadius, y: r.minY))
        path.addLine(to: CGPoint(x: r.midX - notchRadius, y: r.minY))
        
        path.addArc(
            center: CGPoint(x: r.midX, y: r.minY),
            radius: notchRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true // decreasing angle goes down in SwiftUI (180 -> 90 -> 0)
        )
        
        path.addLine(to: CGPoint(x: r.maxX - cornerRadius, y: r.minY))
        path.addArc(center: CGPoint(x: r.maxX - cornerRadius, y: r.minY + cornerRadius), radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cornerRadius))
        path.addArc(center: CGPoint(x: r.maxX - cornerRadius, y: r.maxY - cornerRadius), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        path.addLine(to: CGPoint(x: r.minX + cornerRadius, y: r.maxY))
        path.addArc(center: CGPoint(x: r.minX + cornerRadius, y: r.maxY - cornerRadius), radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + cornerRadius))
        path.addArc(center: CGPoint(x: r.minX + cornerRadius, y: r.minY + cornerRadius), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        return path
    }
}

struct EventTicketShell<Content: View>: View {
    let palette: PassPalette
    var appIcon: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                LinearGradient(colors: [palette.top, palette.mid, palette.bottom], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(EventTicketShape())
            .overlay {
                EventTicketShape()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), palette.border, Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .bottomLeading) {
                if let appIcon {
                    Image(systemName: appIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(20)
                }
            }
            .overlay(alignment: .top) {
                // Specular sheen
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                .clipShape(EventTicketShape())
                .allowsHitTesting(false)
            }
            .shadow(color: palette.glow, radius: 28, y: 16)
            .shadow(color: Color.black.opacity(0.45), radius: 18, y: 10)
    }
}

struct EventTicketHeader: View {
    let title: String
    let subtitle: String?
    let topLeftLogo: LogoTile?
    let rightText1: String?
    let rightText2: String?
    var brandColor: Color = .white

    var body: some View {
        HStack(alignment: .top) {
            if let topLeftLogo {
                topLeftLogo
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(brandColor)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(brandColor.opacity(0.8))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if let r1 = rightText1 {
                    Text(r1.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                if let r2 = rightText2 {
                    Text(r2)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }
}

struct PassMetaBar: View {
    let left: String
    let right: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 7, height: 7)
                    .shadow(color: tint.opacity(0.8), radius: 4)
                Text(left)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(0.5)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(right)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(tint.opacity(0.95))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(tint.opacity(0.35), lineWidth: 1))
                )
        }
        .padding(.horizontal, 2)
    }
}

struct LogoTile: View {
    let systemImage: String
    let colors: [Color]
    var glyphColor: Color = .white

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(glyphColor)
            )
            .shadow(color: colors.first?.opacity(0.45) ?? .clear, radius: 8, y: 3)
    }
}

struct MonoLabel: View {
    let text: String
    var color: Color = Color.white.opacity(0.45)
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .monospaced()
            .foregroundStyle(color)
            .tracking(0.9)
    }
}

struct FieldBlock: View {
    let label: String
    let value: String
    var sub: String? = nil
    var align: HorizontalAlignment = .leading
    var valueColor: Color = .white
    var labelColor: Color = Color.white.opacity(0.45)
    var valueSize: CGFloat = 15

    var body: some View {
        VStack(alignment: align, spacing: 3) {
            MonoLabel(text: label, color: labelColor)
            Text(value)
                .font(.system(size: valueSize, weight: .bold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(align == .trailing ? .trailing : .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let sub, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: align == .trailing ? .trailing : .leading)
    }
}

struct StripHero: View {
    let title: String
    let badge: String?
    var trailing: String? = nil
    let palette: PassPalette
    var height: CGFloat = 128
    var titleBinding: Binding<String>? = nil
    var thumbnailImage: String? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Atmospheric mesh
            LinearGradient(
                colors: [
                    palette.accent.opacity(0.55),
                    palette.mid,
                    palette.bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 160
            )
            LinearGradient(
                colors: [.clear, palette.mid.opacity(0.2), palette.bottom],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if let badge, !badge.isEmpty {
                        Text(badge.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.accentSoft)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black.opacity(0.55))
                                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                            )
                    }
                    Group {
                        if let titleBinding {
                            TextField(title, text: titleBinding, axis: .vertical)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                                .lineLimit(2)
                        } else {
                            Text(title)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                                .lineLimit(2)
                        }
                    }
                }
                Spacer(minLength: 8)
                if let thumbnailImage {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 54, height: 72)
                        .overlay(
                            Image(systemName: thumbnailImage)
                                .font(.system(size: 24))
                                .foregroundStyle(Color.white.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                } else if let trailing, !trailing.isEmpty {
                    Text(trailing)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
                }
            }
            .padding(16)
        }
        .frame(height: height)
    }
}

struct SoftDivider: View {
    var tint: Color = Color.white.opacity(0.08)
    var body: some View {
        Rectangle().fill(tint).frame(height: 1)
    }
}

struct TicketNotchDivider: View {
    let bg: Color
    var body: some View {
        ZStack {
            SoftDivider(tint: Color.white.opacity(0.08))
            HStack {
                Circle().fill(bg).frame(width: 18, height: 18).offset(x: -9)
                Spacer()
                // dashed perforations
                HStack(spacing: 5) {
                    ForEach(0..<18, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.14)).frame(width: 6, height: 1.5)
                    }
                }
                Spacer()
                Circle().fill(bg).frame(width: 18, height: 18).offset(x: 9)
            }
        }
        .frame(height: 18)
        .padding(.vertical, 2)
    }
}

