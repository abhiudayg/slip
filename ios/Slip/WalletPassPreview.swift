import SwiftUI

/// Stitch-faithful Apple Wallet pass cards (stitch_indian_wallet_pass_studio).
struct WalletPassPreview: View {
    let brandId: String
    let displayName: String
    @Binding var fields: [String: String]
    var accentRGB: String? = nil
    /// When true, primary values on brand cards are inline-editable.
    var editable: Bool = true

    var body: some View {
        Group {
            switch brandId {
            case "airbnb": AirbnbRoomKeyCard(fields: $fields, editable: editable)
            case "bookmyshow": BookMyShowTicketCard(fields: fields)
            case "district": DistrictFestivalCard(fields: fields)
            case "irctc": IRCTCRailCard(fields: fields)
            case "indigo": IndigoBoardingCard(fields: fields)
            case "namma-metro": NammaMetroCard(fields: fields)
            case "redbus": RedBusCard(fields: fields)
            case "zoomcar": ZoomcarKeylessCard(fields: fields)
            case "upi": UPIPayPassCard(fields: fields)
            case "easydiner": EazyDinerPrimeCard(fields: fields)
            case "zomato-dineout": ZomatoDiningCard(fields: fields)
            case "swiggy-dineout": SwiggyDineoutCard(fields: fields)
            default:
                GenericStitchCard(brandId: brandId, displayName: displayName, fields: fields, accentRGB: accentRGB)
            }
        }
        // Force card rebuild when any field value changes (SwiftUI can miss deep dict diffs).
        .id(fields.keys.sorted().map { "\($0)=\(fields[$0] ?? "")" }.joined(separator: "|"))
    }

    static func value(_ fields: [String: String], _ keys: [String], fallback: String = "—") -> String {
        for key in keys {
            if let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
        }
        return fallback
    }

    static func abbreviate(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 4 { return t.uppercased() }
        if let paren = t.split(separator: "(").last?.split(separator: ")").first, paren.count <= 4 {
            return String(paren).uppercased()
        }
        return String(t.prefix(3)).uppercased()
    }
}

// MARK: - Design tokens / shells

private struct PassPalette {
    var top: Color
    var mid: Color
    var bottom: Color
    var accent: Color
    var accentSoft: Color
    var border: Color
    var glow: Color
}

private enum PassPalettes {
    static let airbnb = PassPalette(
        top: Color(red: 0.13, green: 0.07, blue: 0.09),
        mid: Color(red: 0.10, green: 0.055, blue: 0.07),
        bottom: Color(red: 0.07, green: 0.035, blue: 0.047),
        accent: Color(red: 1.0, green: 0.22, blue: 0.36),
        accentSoft: Color(red: 1.0, green: 0.59, blue: 0.67),
        border: Color(red: 1.0, green: 0.22, blue: 0.36).opacity(0.28),
        glow: Color(red: 0.55, green: 0.05, blue: 0.15).opacity(0.55)
    )
    static let bms = PassPalette(
        top: Color(red: 0.12, green: 0.04, blue: 0.05),
        mid: Color(red: 0.09, green: 0.03, blue: 0.035),
        bottom: Color(red: 0.05, green: 0.01, blue: 0.02),
        accent: Color(red: 0.86, green: 0.21, blue: 0.35),
        accentSoft: Color(red: 1.0, green: 0.55, blue: 0.62),
        border: Color(red: 0.86, green: 0.21, blue: 0.35).opacity(0.28),
        glow: Color(red: 0.45, green: 0.02, blue: 0.08).opacity(0.55)
    )
    static let irctc = PassPalette(
        top: Color(red: 0.09, green: 0.14, blue: 0.23),
        mid: Color(red: 0.07, green: 0.10, blue: 0.17),
        bottom: Color(red: 0.04, green: 0.06, blue: 0.11),
        accent: Color(red: 0.96, green: 0.70, blue: 0.20),
        accentSoft: Color(red: 0.98, green: 0.82, blue: 0.45),
        border: Color(red: 0.96, green: 0.70, blue: 0.20).opacity(0.28),
        glow: Color(red: 0.05, green: 0.15, blue: 0.40).opacity(0.55)
    )
    static let indigo = PassPalette(
        top: Color(red: 0.035, green: 0.105, blue: 0.26),
        mid: Color(red: 0.027, green: 0.082, blue: 0.21),
        bottom: Color(red: 0.015, green: 0.047, blue: 0.13),
        accent: Color(red: 0.25, green: 0.45, blue: 0.95),
        accentSoft: Color(red: 0.55, green: 0.70, blue: 1.0),
        border: Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.28),
        glow: Color(red: 0.05, green: 0.12, blue: 0.45).opacity(0.55)
    )
    static let metro = PassPalette(
        top: Color(red: 0.12, green: 0.07, blue: 0.22),
        mid: Color(red: 0.08, green: 0.05, blue: 0.16),
        bottom: Color(red: 0.05, green: 0.03, blue: 0.10),
        accent: Color(red: 0.55, green: 0.30, blue: 0.95),
        accentSoft: Color(red: 0.75, green: 0.60, blue: 1.0),
        border: Color(red: 0.55, green: 0.30, blue: 0.95).opacity(0.3),
        glow: Color(red: 0.25, green: 0.08, blue: 0.45).opacity(0.5)
    )
    static let redbus = PassPalette(
        top: Color(red: 0.18, green: 0.05, blue: 0.05),
        mid: Color(red: 0.12, green: 0.04, blue: 0.04),
        bottom: Color(red: 0.07, green: 0.02, blue: 0.02),
        accent: Color(red: 0.90, green: 0.18, blue: 0.20),
        accentSoft: Color(red: 1.0, green: 0.55, blue: 0.55),
        border: Color(red: 0.90, green: 0.18, blue: 0.20).opacity(0.28),
        glow: Color(red: 0.40, green: 0.02, blue: 0.05).opacity(0.5)
    )
    static let zoomcar = PassPalette(
        top: Color(red: 0.09, green: 0.14, blue: 0.06),
        mid: Color(red: 0.06, green: 0.09, blue: 0.04),
        bottom: Color(red: 0.03, green: 0.05, blue: 0.02),
        accent: Color(red: 0.55, green: 0.90, blue: 0.25),
        accentSoft: Color(red: 0.70, green: 0.95, blue: 0.45),
        border: Color(red: 0.55, green: 0.90, blue: 0.25).opacity(0.28),
        glow: Color(red: 0.15, green: 0.35, blue: 0.05).opacity(0.5)
    )
    static let upi = PassPalette(
        top: Color(red: 0.05, green: 0.10, blue: 0.18),
        mid: Color(red: 0.04, green: 0.08, blue: 0.14),
        bottom: Color(red: 0.02, green: 0.05, blue: 0.09),
        accent: Color(red: 0.25, green: 0.55, blue: 0.95),
        accentSoft: Color(red: 0.55, green: 0.75, blue: 1.0),
        border: Color(red: 0.25, green: 0.55, blue: 0.95).opacity(0.28),
        glow: Color(red: 0.05, green: 0.2, blue: 0.45).opacity(0.5)
    )
    static let zomato = PassPalette(
        top: Color(red: 0.165, green: 0.055, blue: 0.08),
        mid: Color(red: 0.11, green: 0.03, blue: 0.05),
        bottom: Color(red: 0.06, green: 0.012, blue: 0.024),
        accent: Color(red: 0.89, green: 0.22, blue: 0.27),
        accentSoft: Color(red: 1.0, green: 0.60, blue: 0.65),
        border: Color(red: 0.89, green: 0.22, blue: 0.27).opacity(0.28),
        glow: Color(red: 0.40, green: 0.05, blue: 0.08).opacity(0.5)
    )
    static let easydiner = PassPalette(
        top: Color(red: 0.14, green: 0.10, blue: 0.05),
        mid: Color(red: 0.10, green: 0.07, blue: 0.03),
        bottom: Color(red: 0.06, green: 0.04, blue: 0.02),
        accent: Color(red: 0.90, green: 0.65, blue: 0.22),
        accentSoft: Color(red: 0.98, green: 0.82, blue: 0.45),
        border: Color(red: 0.90, green: 0.65, blue: 0.22).opacity(0.28),
        glow: Color(red: 0.35, green: 0.22, blue: 0.05).opacity(0.5)
    )
    static let swiggy = PassPalette(
        top: Color(red: 0.16, green: 0.09, blue: 0.04),
        mid: Color(red: 0.11, green: 0.06, blue: 0.03),
        bottom: Color(red: 0.07, green: 0.03, blue: 0.015),
        accent: Color(red: 0.99, green: 0.50, blue: 0.10),
        accentSoft: Color(red: 1.0, green: 0.70, blue: 0.40),
        border: Color(red: 0.99, green: 0.50, blue: 0.10).opacity(0.28),
        glow: Color(red: 0.40, green: 0.18, blue: 0.02).opacity(0.5)
    )
    static let district = PassPalette(
        top: Color(red: 0.10, green: 0.06, blue: 0.18),
        mid: Color(red: 0.07, green: 0.04, blue: 0.13),
        bottom: Color(red: 0.04, green: 0.02, blue: 0.08),
        accent: Color(red: 0.49, green: 0.23, blue: 0.93),
        accentSoft: Color(red: 0.72, green: 0.58, blue: 1.0),
        border: Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.3),
        glow: Color(red: 0.22, green: 0.08, blue: 0.45).opacity(0.5)
    )
}

private struct PassShell<Content: View>: View {
    let palette: PassPalette
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                LinearGradient(colors: [palette.top, palette.mid, palette.bottom], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), palette.border, Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                // Specular sheen
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .allowsHitTesting(false)
            }
            .shadow(color: palette.glow, radius: 28, y: 16)
            .shadow(color: Color.black.opacity(0.45), radius: 18, y: 10)
    }
}

private struct PassMetaBar: View {
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
                    Capsule()
                        .fill(tint.opacity(0.12))
                        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
                )
        }
        .padding(.horizontal, 2)
    }
}

private struct LogoTile: View {
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

private struct MonoLabel: View {
    let text: String
    var color: Color = Color.white.opacity(0.45)
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .tracking(0.9)
    }
}

private struct FieldBlock: View {
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

private struct StripHero: View {
    let title: String
    let badge: String?
    var trailing: String? = nil
    let palette: PassPalette
    var height: CGFloat = 128
    var titleBinding: Binding<String>? = nil

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
                                Capsule()
                                    .fill(Color.black.opacity(0.55))
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
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
                if let trailing, !trailing.isEmpty {
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

private struct SoftDivider: View {
    var tint: Color = Color.white.opacity(0.08)
    var body: some View {
        Rectangle().fill(tint).frame(height: 1)
    }
}

private struct TicketNotchDivider: View {
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
                        Capsule().fill(Color.white.opacity(0.14)).frame(width: 6, height: 1.5)
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

private struct QRPanel: View {
    let caption: String
    let alt: String
    let accent: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 132, height: 132)
                    .shadow(color: accent.opacity(0.25), radius: 16, y: 6)
                Image(systemName: "qrcode")
                    .font(.system(size: 78, weight: .regular))
                    .foregroundStyle(.black.opacity(0.92))
            }
            Text(caption.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.85))
                .tracking(1.2)
            if !alt.isEmpty {
                Text(alt)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct NFCPanel: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                    .frame(width: 86, height: 86)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.28), tint.opacity(0.06)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 40
                        )
                    )
                    .frame(width: 68, height: 68)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
                    .rotationEffect(.degrees(90))
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(tint.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.38))
    }
}

private struct RouteConnector: View {
    let duration: String
    let tint: Color
    var icon: String = "airplane"

    var body: some View {
        VStack(spacing: 6) {
            Text(duration)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(tint.opacity(0.9))
            HStack(spacing: 0) {
                Circle()
                    .strokeBorder(tint, lineWidth: 2)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(
                        LinearGradient(colors: [tint.opacity(0.7), tint.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                            .offset(y: -10)
                    )
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 88)
        }
    }
}

private struct BrandHeaderRow: View {
    let title: String
    let subtitle: String
    let logo: LogoTile
    let trailingLabel: String
    let trailingValue: String
    let accentSoft: Color
    var trailingColor: Color = .white

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 10) {
                logo
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentSoft.opacity(0.9))
                        .tracking(0.8)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                MonoLabel(text: trailingLabel, color: accentSoft.opacity(0.7))
                Text(trailingValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(trailingColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
}

// MARK: - Airbnb

private struct AirbnbRoomKeyCard: View {
    @Binding var fields: [String: String]
    var editable: Bool = true
    private let p = PassPalettes.airbnb

    var body: some View {
        let property = WalletPassPreview.value(fields, ["property"], fallback: "Stay")
        let propertyType = WalletPassPreview.value(fields, ["property_type"], fallback: "")
        let address = WalletPassPreview.value(fields, ["address", "city"], fallback: "")
        let checkInDate = WalletPassPreview.value(fields, ["check_in"], fallback: "—")
        let checkInTime = WalletPassPreview.value(fields, ["check_in_time"], fallback: "")
        let checkOutDate = WalletPassPreview.value(fields, ["check_out"], fallback: "—")
        let checkOutTime = WalletPassPreview.value(fields, ["check_out_time"], fallback: "")
        let guest = {
            let g = WalletPassPreview.value(fields, ["guest"], fallback: "—")
            let d = WalletPassPreview.value(fields, ["guest_details"], fallback: "")
            return d.isEmpty || d == "—" ? g : "\(g)\n\(d)"
        }()
        // Never fall back to booking_id — that made the PIN look stuck on the confirmation code.
        let pin = WalletPassPreview.value(fields, ["door_pin"], fallback: "")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "")
        let wifi = WalletPassPreview.value(fields, ["wifi_ssid"], fallback: "")

        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC_KEYLESS", right: "APPLE VAS NFC", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Airbnb",
                        subtitle: "Room Key & Access Pass",
                        logo: LogoTile(systemImage: "house.fill", colors: [Color(red: 1, green: 0.22, blue: 0.36), Color(red: 0.88, green: 0.04, blue: 0.25)]),
                        trailingLabel: "Key Status",
                        trailingValue: "● ACTIVE",
                        accentSoft: p.accentSoft,
                        trailingColor: Color(red: 0.3, green: 0.9, blue: 0.55)
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(
                        title: property,
                        badge: propertyType.isEmpty ? nil : propertyType,
                        trailing: nil,
                        palette: p,
                        height: 124,
                        titleBinding: editable ? fieldBinding("property") : nil
                    )
                    if !address.isEmpty && address != "—" {
                        editableLine(key: "address", fallback: address, font: .system(size: 12, weight: .semibold), color: Color.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                    }
                    HStack(alignment: .top) {
                        EditableFieldBlock(
                            label: "Check-In",
                            valueKey: "check_in",
                            fields: $fields,
                            editable: editable,
                            fallback: checkInDate,
                            subKey: "check_in_time",
                            labelColor: p.accentSoft.opacity(0.7)
                        )
                        EditableFieldBlock(
                            label: "Check-Out",
                            valueKey: "check_out",
                            fields: $fields,
                            editable: editable,
                            fallback: checkOutDate,
                            subKey: "check_out_time",
                            align: .trailing,
                            labelColor: p.accentSoft.opacity(0.7)
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(p.accent.opacity(0.08))
                    SoftDivider(tint: p.accent.opacity(0.1))
                    HStack(alignment: .top) {
                        EditableFieldBlock(
                            label: "Guest / Reserved For",
                            valueKey: "guest",
                            fields: $fields,
                            editable: editable,
                            fallback: guest,
                            labelColor: p.accentSoft.opacity(0.7)
                        )
                        EditableFieldBlock(
                            label: "Backup Door PIN",
                            valueKey: "door_pin",
                            fields: $fields,
                            editable: editable,
                            fallback: pin.isEmpty ? "—" : pin,
                            align: .trailing,
                            valueColor: p.accentSoft,
                            labelColor: p.accentSoft.opacity(0.7)
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    NFCPanel(
                        title: "Hold Near Door Lock to Unlock",
                        subtitle: wifi.isEmpty || wifi == "—"
                            ? "Apple VAS NFC • Express Mode Active"
                            : "Apple VAS NFC • Wi-Fi: \(wifi)",
                        tint: p.accent
                    )
                    if !booking.isEmpty {
                        HStack {
                            Text("Confirmation")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(p.accentSoft.opacity(0.8))
                            Spacer()
                            if editable {
                                TextField("Code", text: fieldBinding("booking_id"))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                                    .frame(maxWidth: 160)
                            } else {
                                Text(booking)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(p.accent.opacity(0.1))
                    }
                }
            }
        }
    }

    private func fieldBinding(_ key: String) -> Binding<String> {
        Binding(
            get: { fields[key] ?? "" },
            set: { fields[key] = $0 }
        )
    }

    @ViewBuilder
    private func editableLine(key: String, fallback: String, font: Font, color: Color) -> some View {
        if editable {
            TextField(fallback, text: fieldBinding(key), axis: .vertical)
                .font(font)
                .foregroundStyle(color)
        } else {
            Text(fallback)
                .font(font)
                .foregroundStyle(color)
        }
    }
}

private struct EditableFieldBlock: View {
    let label: String
    let valueKey: String
    @Binding var fields: [String: String]
    var editable: Bool = true
    var fallback: String = "—"
    var subKey: String? = nil
    var align: HorizontalAlignment = .leading
    var valueColor: Color = .white
    var labelColor: Color = Color.white.opacity(0.45)
    var valueSize: CGFloat = 15

    var body: some View {
        let sub = subKey.flatMap { key -> String? in
            let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return v.isEmpty ? nil : v
        }
        VStack(alignment: align, spacing: 3) {
            MonoLabel(text: label, color: labelColor)
            if editable {
                TextField(fallback, text: binding(valueKey), axis: .vertical)
                    .font(.system(size: valueSize, weight: .bold))
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(align == .trailing ? .trailing : .leading)
                    .lineLimit(2)
            } else {
                Text(displayValue)
                    .font(.system(size: valueSize, weight: .bold))
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(align == .trailing ? .trailing : .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            if let subKey {
                if editable {
                    TextField("Time", text: binding(subKey))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(align == .trailing ? .trailing : .leading)
                        .lineLimit(1)
                } else if let sub {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: align == .trailing ? .trailing : .leading)
    }

    private var displayValue: String {
        let v = fields[valueKey]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return v.isEmpty ? fallback : v
    }

    private func binding(_ key: String) -> Binding<String> {
        Binding(
            get: { fields[key] ?? "" },
            set: { fields[key] = $0 }
        )
    }
}

// MARK: - BookMyShow

private struct BookMyShowTicketCard: View {
    let fields: [String: String]
    private let p = PassPalettes.bms

    var body: some View {
        let event = WalletPassPreview.value(fields, ["event"], fallback: "Movie")
        let venue = WalletPassPreview.value(fields, ["venue"], fallback: "—")
        let screen = WalletPassPreview.value(fields, ["screen"], fallback: "")
        let seat = WalletPassPreview.value(fields, ["seat"], fallback: "—")
        let time = WalletPassPreview.value(fields, ["time"], fallback: "—")
        let date = WalletPassPreview.value(fields, ["date"], fallback: "")
        let format = WalletPassPreview.value(fields, ["format"], fallback: "IMAX · DOLBY")
        let certification = WalletPassPreview.value(fields, ["certification"], fallback: "")
        let fnb = WalletPassPreview.value(fields, ["fnb"], fallback: "")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "—")
        let formatBadge = certification.isEmpty || certification == "—" ? format : "\(format) · \(certification)"
        let venueLine = screen.isEmpty || screen == "—" ? venue : "\(venue) · \(screen)"
        let whenLine = date.isEmpty || date == "—" ? time : "\(date) · \(time)"

        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • EVENT_TICKET", right: "TURNSTILE QR", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "BookMyShow",
                        subtitle: "Cinema Ticket",
                        logo: LogoTile(systemImage: "ticket.fill", colors: [p.accent, Color(red: 0.6, green: 0.05, blue: 0.2)]),
                        trailingLabel: "Booking ID",
                        trailingValue: booking,
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: event, badge: formatBadge, trailing: nil, palette: p)
                    VStack(alignment: .leading, spacing: 4) {
                        MonoLabel(text: "Cinema Audi & Screen", color: p.accentSoft.opacity(0.7))
                        Text(venueLine)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(p.accent.opacity(0.08))
                    HStack(spacing: 10) {
                        fieldChip("Showtime", whenLine, p)
                        fieldChip("Seats", seat, p)
                    }
                    .padding(14)
                    if !fnb.isEmpty && fnb != "—" {
                        Text(fnb)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(p.accentSoft.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 10)
                    }
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan at audi turnstile", alt: booking, accent: p.accentSoft)
                }
            }
        }
    }

    private func fieldChip(_ label: String, _ value: String, _ p: PassPalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoLabel(text: label, color: p.accentSoft.opacity(0.7))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(p.accent.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(p.accent.opacity(0.22), lineWidth: 1))
        )
    }
}

// MARK: - District / Dining / Zoom / UPI / Metro

private struct DistrictFestivalCard: View {
    let fields: [String: String]
    private let p = PassPalettes.district
    var body: some View {
        let event = WalletPassPreview.value(fields, ["event"], fallback: "Festival")
        let venue = WalletPassPreview.value(fields, ["venue"], fallback: "—")
        let seat = WalletPassPreview.value(fields, ["seat"], fallback: "")
        let screen = WalletPassPreview.value(fields, ["screen"], fallback: "")
        let tier = WalletPassPreview.value(fields, ["tier"], fallback: "GA")
        let gate = WalletPassPreview.value(fields, ["gate"], fallback: "—")
        let time = WalletPassPreview.value(fields, ["time"], fallback: "—")
        let date = WalletPassPreview.value(fields, ["date"], fallback: "")
        let booking = WalletPassPreview.value(fields, ["booking_id", "qr_data"], fallback: "—")
        let whenLine = date.isEmpty || date == "—" ? time : "\(date) · \(time)"
        let seatLine: String = {
            var parts: [String] = []
            if !screen.isEmpty && screen != "—" { parts.append(screen) }
            if !seat.isEmpty && seat != "—" { parts.append(seat) }
            return parts.isEmpty ? gate : parts.joined(separator: " · ")
        }()

        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • EVENT_TICKET", right: "NFC WRISTBAND", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "District",
                        subtitle: "Festival Pass · NFC Wristband",
                        logo: LogoTile(systemImage: "bolt.fill", colors: [p.accent, Color(red: 0.3, green: 0.1, blue: 0.6)]),
                        trailingLabel: "Tier",
                        trailingValue: tier.uppercased(),
                        accentSoft: p.accentSoft,
                        trailingColor: p.accentSoft
                    )
                    StripHero(title: event, badge: "Live Arena", trailing: nil, palette: p, height: 110)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
                    HStack {
                        FieldBlock(label: "Date & Showtime", value: whenLine, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: seatLine == gate ? "Fast Entry" : "Screen / Seats", value: seatLine, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    NFCPanel(title: "Tap iPhone at Turnstile NFC Scanner", subtitle: "Apple VAS · Express Entry · \(booking)", tint: p.accent)
                }
            }
        }
    }
}

private struct DiningShell: View {
    let brand: String
    let subtitle: String
    let meta: (String, String)
    let palette: PassPalette
    let logoColors: [Color]
    let restaurant: String
    let time: String
    let guests: String
    let booking: String
    let footer: String
    var badge: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            PassMetaBar(left: meta.0, right: meta.1, tint: palette.accent)
            PassShell(palette: palette) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: brand,
                        subtitle: subtitle,
                        logo: LogoTile(systemImage: "fork.knife", colors: logoColors),
                        trailingLabel: "Party",
                        trailingValue: guests,
                        accentSoft: palette.accentSoft
                    )
                    SoftDivider(tint: palette.accent.opacity(0.12))
                    StripHero(title: restaurant, badge: badge, palette: palette, height: 118)
                    HStack {
                        FieldBlock(label: "Date & Slot", value: time, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "Booking", value: booking, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    .background(palette.accent.opacity(0.08))
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: footer, alt: booking, accent: palette.accentSoft)
                }
            }
        }
    }
}

private struct EazyDinerPrimeCard: View {
    let fields: [String: String]
    var body: some View {
        DiningShell(
            brand: "EazyDiner",
            subtitle: "VIP Culinary Pass",
            meta: ("PASSKIT • STORE_CARD", "VIP PRIME"),
            palette: PassPalettes.easydiner,
            logoColors: [PassPalettes.easydiner.accent, Color(red: 0.7, green: 0.4, blue: 0.05)],
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size", "guest"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "Scan at bill settlement",
            badge: "Prime · 25% Off"
        )
    }
}

private struct ZomatoDiningCard: View {
    let fields: [String: String]
    var body: some View {
        DiningShell(
            brand: "Zomato",
            subtitle: "Table Reservation · Confirmed",
            meta: ("PASSKIT • EVENT_TICKET", "PODIUM BEACON"),
            palette: PassPalettes.zomato,
            logoColors: [PassPalettes.zomato.accent, Color(red: 0.6, green: 0.05, blue: 0.12)],
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "Show at hostess podium",
            badge: "Reservation"
        )
    }
}

private struct SwiggyDineoutCard: View {
    let fields: [String: String]
    var body: some View {
        DiningShell(
            brand: "Swiggy Dineout",
            subtitle: "Dining Coupon & Bill Pay",
            meta: ("PASSKIT • COUPON", "CODE 128"),
            palette: PassPalettes.swiggy,
            logoColors: [PassPalettes.swiggy.accent, Color(red: 0.85, green: 0.3, blue: 0.05)],
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "Scan or present to server",
            badge: "Dineout Offer"
        )
    }
}

// MARK: - Boarding / transit

private struct BoardingCard: View {
    let brand: String
    let subtitle: String
    let metaLeft: String
    let metaRight: String
    let palette: PassPalette
    let logo: LogoTile
    let fromCode: String
    let fromName: String
    let toCode: String
    let toName: String
    let headerLeft: (String, String)
    let headerRight: (String, String)
    let midLeft: (String, String)
    let midRight: (String, String)
    let duration: String
    let routeIcon: String
    let barcodeAlt: String
    let barcodeCaption: String

    var body: some View {
        VStack(spacing: 12) {
            PassMetaBar(left: metaLeft, right: metaRight, tint: palette.accent)
            PassShell(palette: palette) {
                VStack(spacing: 0) {
                    // Top accent ribbon
                    LinearGradient(colors: [palette.accent, palette.accent.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        .frame(height: 5)

                    BrandHeaderRow(
                        title: brand,
                        subtitle: subtitle,
                        logo: logo,
                        trailingLabel: headerLeft.0,
                        trailingValue: headerLeft.1,
                        accentSoft: palette.accentSoft
                    )
                    SoftDivider(tint: palette.accent.opacity(0.12))

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(fromCode)
                                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(fromName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .lineLimit(1)
                        }
                        Spacer()
                        RouteConnector(duration: duration, tint: palette.accent, icon: routeIcon)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(toCode)
                                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(toName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [palette.accent.opacity(0.08), .clear, palette.accent.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                    HStack {
                        FieldBlock(label: headerRight.0, value: headerRight.1, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: midLeft.0, value: midLeft.1, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)

                    SoftDivider(tint: palette.accent.opacity(0.1))

                    HStack {
                        FieldBlock(label: midRight.0, value: midRight.1, labelColor: palette.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)

                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: barcodeCaption, alt: barcodeAlt, accent: palette.accentSoft)
                }
            }
        }
    }
}

private struct IRCTCRailCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.irctc
        BoardingCard(
            brand: "IRCTC",
            subtitle: "Indian Railways · e-Ticket",
            metaLeft: "PASSKIT • TRANSIT_PASS",
            metaRight: "INDIAN RAILWAYS QR",
            palette: p,
            logo: LogoTile(systemImage: "train.side.front.car", colors: [p.accent, Color(red: 0.85, green: 0.5, blue: 0.05)], glyphColor: Color(red: 0.08, green: 0.08, blue: 0.1)),
            fromCode: WalletPassPreview.abbreviate(WalletPassPreview.value(fields, ["origin"], fallback: "—")),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Origin"),
            toCode: WalletPassPreview.abbreviate(WalletPassPreview.value(fields, ["destination"], fallback: "—")),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Destination"),
            headerLeft: ("Train", WalletPassPreview.value(fields, ["train"], fallback: "—")),
            headerRight: ("Depart", WalletPassPreview.value(fields, ["dep", "time"], fallback: "—")),
            midLeft: ("Arrive", WalletPassPreview.value(fields, ["arr"], fallback: "—")),
            midRight: ("Coach / Berth", "\(WalletPassPreview.value(fields, ["coach"], fallback: "—")) / \(WalletPassPreview.value(fields, ["seat"], fallback: "—"))"),
            duration: WalletPassPreview.value(fields, ["duration"], fallback: "Journey"),
            routeIcon: "train.side.front.car",
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "booking_id", "qr_data"], fallback: ""),
            barcodeCaption: "Official TTE scanner QR"
        )
    }
}

private struct IndigoBoardingCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.indigo
        BoardingCard(
            brand: "IndiGo",
            subtitle: "Boarding Pass",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: "AZTEC 2D",
            palette: p,
            logo: LogoTile(systemImage: "airplane", colors: [p.accent, Color(red: 0.1, green: 0.25, blue: 0.7)]),
            fromCode: WalletPassPreview.value(fields, ["origin"], fallback: "—").uppercased(),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Origin"),
            toCode: WalletPassPreview.value(fields, ["destination"], fallback: "—").uppercased(),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Destination"),
            headerLeft: ("Flight", WalletPassPreview.value(fields, ["flight"], fallback: "—")),
            headerRight: ("Depart", WalletPassPreview.value(fields, ["dep", "time"], fallback: "—")),
            midLeft: ("Gate / Seat", "\(WalletPassPreview.value(fields, ["gate"], fallback: "—")) · \(WalletPassPreview.value(fields, ["seat"], fallback: "—"))"),
            midRight: ("Passenger", WalletPassPreview.value(fields, ["passenger", "name"], fallback: "—")),
            duration: WalletPassPreview.value(fields, ["duration"], fallback: "Flight"),
            routeIcon: "airplane",
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "booking_id", "qr_data"], fallback: ""),
            barcodeCaption: "IATA BCBP · e-ticket scan"
        )
    }
}

private struct RedBusCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.redbus
        BoardingCard(
            brand: "redBus",
            subtitle: "Intercity Sleeper",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: "ON TIME",
            palette: p,
            logo: LogoTile(systemImage: "bus.fill", colors: [p.accent, Color(red: 0.6, green: 0.05, blue: 0.08)]),
            fromCode: WalletPassPreview.abbreviate(WalletPassPreview.value(fields, ["origin"], fallback: "BLR")),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Boarding"),
            toCode: WalletPassPreview.abbreviate(WalletPassPreview.value(fields, ["destination"], fallback: "HYD")),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Drop off"),
            headerLeft: ("PNR", WalletPassPreview.value(fields, ["pnr", "booking_id"], fallback: "—")),
            headerRight: ("Depart", WalletPassPreview.value(fields, ["dep", "time"], fallback: "—")),
            midLeft: ("Arrive", WalletPassPreview.value(fields, ["arr"], fallback: "—")),
            midRight: ("Seat · Passenger", "\(WalletPassPreview.value(fields, ["seat"], fallback: "—")) · \(WalletPassPreview.value(fields, ["passenger", "name"], fallback: "—"))"),
            duration: WalletPassPreview.value(fields, ["duration"], fallback: "Trip"),
            routeIcon: "bus.fill",
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "qr_data"], fallback: ""),
            barcodeCaption: "Boarding QR"
        )
    }
}

private struct NammaMetroCard: View {
    let fields: [String: String]
    private let p = PassPalettes.metro
    var body: some View {
        let origin = WalletPassPreview.value(fields, ["origin"], fallback: "Origin")
        let dest = WalletPassPreview.value(fields, ["destination"], fallback: "Destination")
        let booking = WalletPassPreview.value(fields, ["booking_id", "qr_data"], fallback: "—")
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • BOARDING_PASS", right: "BMRCL QR", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Namma Metro",
                        subtitle: "BMRCL Rapid Transit",
                        logo: LogoTile(systemImage: "tram.fill", colors: [p.accent, Color(red: 0.3, green: 0.1, blue: 0.55)]),
                        trailingLabel: "Ticket Type",
                        trailingValue: "QR SINGLE",
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Origin Station", value: origin, labelColor: p.accentSoft.opacity(0.7), valueSize: 17)
                        RouteConnector(duration: "Metro", tint: p.accent, icon: "tram.fill")
                        FieldBlock(label: "Destination", value: dest, align: .trailing, labelColor: p.accentSoft.opacity(0.7), valueSize: 17)
                    }
                    .padding(18)
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Token / Pass ID", alt: booking, accent: p.accentSoft)
                }
            }
        }
    }
}

private struct ZoomcarKeylessCard: View {
    let fields: [String: String]
    private let p = PassPalettes.zoomcar
    var body: some View {
        let vehicle = WalletPassPreview.value(fields, ["vehicle"], fallback: "Vehicle")
        let pickup = WalletPassPreview.value(fields, ["pickup"], fallback: "—")
        let drop = WalletPassPreview.value(fields, ["drop_off"], fallback: "—")
        let guest = WalletPassPreview.value(fields, ["guest"], fallback: "—")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "—")
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC_KEYLESS", right: "KEYLESS SMARTLOCK", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Zoomcar",
                        subtitle: "Self-Drive Rental Pass",
                        logo: LogoTile(systemImage: "car.fill", colors: [p.accent, Color(red: 0.2, green: 0.55, blue: 0.15)], glyphColor: Color(red: 0.05, green: 0.08, blue: 0.03)),
                        trailingLabel: "Key Status",
                        trailingValue: "READY",
                        accentSoft: p.accentSoft,
                        trailingColor: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: vehicle, badge: "Self-Drive", palette: p, height: 112)
                    HStack {
                        FieldBlock(label: "Pickup & Unlock", value: pickup, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Drop Off & Lock", value: drop, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.06))
                    NFCPanel(title: "Hold iPhone Near Windshield Reader", subtitle: "Express Mode · Backup PIN available", tint: p.accent)
                    HStack {
                        FieldBlock(label: "Driver", value: guest, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Booking / PIN", value: booking, align: .trailing, valueColor: p.accentSoft, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                }
            }
        }
    }
}

private struct UPIPayPassCard: View {
    let fields: [String: String]
    private let p = PassPalettes.upi
    var body: some View {
        let name = WalletPassPreview.value(fields, ["name"], fallback: "Payee")
        let vpa = WalletPassPreview.value(fields, ["vpa", "qr_data"], fallback: "—")
        let bank = WalletPassPreview.value(fields, ["bank"], fallback: "—")
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • STORE_CARD", right: "NPCI 2.0", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "UPI PayPass",
                        subtitle: "Instant Receive & Pay",
                        logo: LogoTile(systemImage: "qrcode", colors: [p.accent, Color(red: 0.1, green: 0.3, blue: 0.7)]),
                        trailingLabel: "Status",
                        trailingValue: "ACTIVE VPA",
                        accentSoft: p.accentSoft,
                        trailingColor: Color(red: 0.3, green: 0.9, blue: 0.55)
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    FieldBlock(label: "Account Holder", value: name, labelColor: p.accentSoft.opacity(0.7), valueSize: 20)
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                    HStack {
                        FieldBlock(label: "VPA", value: vpa, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Linked Bank", value: bank, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan to pay", alt: vpa, accent: p.accentSoft)
                }
            }
        }
    }
}

private struct GenericStitchCard: View {
    let brandId: String
    let displayName: String
    let fields: [String: String]
    var accentRGB: String? = nil

    var body: some View {
        let tint = SlipTheme.color(fromRGB: accentRGB) ?? SlipTheme.accent
        let palette = PassPalette(
            top: Color(red: 0.09, green: 0.09, blue: 0.13),
            mid: Color(red: 0.06, green: 0.06, blue: 0.09),
            bottom: Color(red: 0.04, green: 0.04, blue: 0.06),
            accent: tint,
            accentSoft: tint.opacity(0.85),
            border: tint.opacity(0.28),
            glow: tint.opacity(0.35)
        )
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC", right: brandId.uppercased(), tint: tint)
            PassShell(palette: palette) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    ForEach(Array(fields.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }.prefix(6)), id: \.key) { key, value in
                        FieldBlock(label: key.replacingOccurrences(of: "_", with: " "), value: value, labelColor: tint.opacity(0.7))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
