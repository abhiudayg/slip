import SwiftUI

/// Stitch-faithful Apple Wallet pass cards (from stitch_indian_wallet_pass_studio).
/// Renders ~PassKit anatomy with brand-specific HUD chrome matching the HTML templates.
struct WalletPassPreview: View {
    let brandId: String
    let displayName: String
    let fields: [String: String]
    var accentRGB: String? = nil

    var body: some View {
        Group {
            switch brandId {
            case "airbnb":
                AirbnbRoomKeyCard(fields: fields)
            case "bookmyshow":
                BookMyShowTicketCard(fields: fields)
            case "district":
                DistrictFestivalCard(fields: fields)
            case "irctc":
                IRCTCRailCard(fields: fields)
            case "indigo":
                IndigoBoardingCard(fields: fields)
            case "namma-metro":
                NammaMetroCard(fields: fields)
            case "redbus":
                RedBusCard(fields: fields)
            case "zoomcar":
                ZoomcarKeylessCard(fields: fields)
            case "upi":
                UPIPayPassCard(fields: fields)
            case "easydiner":
                EazyDinerPrimeCard(fields: fields)
            case "zomato-dineout":
                ZomatoDiningCard(fields: fields)
            case "swiggy-dineout":
                SwiggyDineoutCard(fields: fields)
            default:
                GenericStitchCard(brandId: brandId, displayName: displayName, fields: fields, accentRGB: accentRGB)
            }
        }
    }

    static func value(_ fields: [String: String], _ keys: [String], fallback: String = "—") -> String {
        for key in keys {
            if let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
        }
        return fallback
    }
}

// MARK: - Shared primitives

private struct PassMetaChip: View {
    let left: String
    let right: String
    var tint: Color = Color(red: 1, green: 0.35, blue: 0.45)

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(left)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.6)
            }
            Spacer()
            Text(right)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(tint.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1).background(Capsule().fill(tint.opacity(0.12))))
        }
        .padding(.horizontal, 4)
    }
}

private struct MonoLabel: View {
    let text: String
    var color: Color = Color.white.opacity(0.45)
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color)
            .tracking(0.8)
    }
}

private struct FieldBlock: View {
    let label: String
    let value: String
    var sub: String? = nil
    var align: HorizontalAlignment = .leading
    var valueColor: Color = .white
    var labelColor: Color = Color.white.opacity(0.45)

    var body: some View {
        VStack(alignment: align, spacing: 2) {
            MonoLabel(text: label, color: labelColor)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(align == .trailing ? .trailing : .leading)
                .lineLimit(2)
            if let sub, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: align == .trailing ? .trailing : .leading)
    }
}

private struct QRFooter: View {
    let caption: String
    let alt: String
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "qrcode")
                        .font(.system(size: 72))
                        .foregroundStyle(.black)
                )
            Text(caption)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.55))
                .tracking(1)
            if !alt.isEmpty {
                Text(alt)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct NFCUnlockFooter: View {
    let title: String
    let subtitle: String
    var tint: Color = Color(red: 1, green: 0.35, blue: 0.45)

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(tint)
                    .rotationEffect(.degrees(90))
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(tint.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.black.opacity(0.35))
    }
}

// MARK: - Airbnb (GENERIC_KEYLESS / Room Key)

private struct AirbnbRoomKeyCard: View {
    let fields: [String: String]
    private let rose = Color(red: 1, green: 0.22, blue: 0.36)
    private let roseMuted = Color(red: 1, green: 0.55, blue: 0.65)

    var body: some View {
        let property = WalletPassPreview.value(fields, ["property"], fallback: "Stay")
        let checkIn = WalletPassPreview.value(fields, ["check_in"], fallback: "—")
        let checkOut = WalletPassPreview.value(fields, ["check_out"], fallback: "—")
        let guest = WalletPassPreview.value(fields, ["guest"], fallback: "—")
        let pin = WalletPassPreview.value(fields, ["door_pin", "booking_id"], fallback: "—")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "")

        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • GENERIC_KEYLESS", right: "APPLE VAS NFC", tint: rose)

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [Color(red: 1, green: 0.22, blue: 0.36), Color(red: 0.88, green: 0.04, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "house.fill").foregroundStyle(.white).font(.system(size: 16, weight: .bold)))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Airbnb").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                                Text("SUPERHOST")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(roseMuted)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 4).strokeBorder(rose.opacity(0.35)).background(RoundedRectangle(cornerRadius: 4).fill(rose.opacity(0.18))))
                            }
                            Text("ROOM KEY & ACCESS PASS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(roseMuted.opacity(0.85))
                                .tracking(0.8)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        MonoLabel(text: "Key Status", color: roseMuted.opacity(0.7))
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("ACTIVE").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.green)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

                // Strip hero
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [Color(red: 0.35, green: 0.12, blue: 0.18), Color(red: 0.12, green: 0.06, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    LinearGradient(colors: [.clear, Color(red: 0.1, green: 0.05, blue: 0.07)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ENTIRE HOME")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(roseMuted)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.55)))
                        Text(property)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(16)
                }
                .frame(height: 120)

                // Dates
                HStack {
                    FieldBlock(label: "Check-In", value: checkIn, labelColor: roseMuted.opacity(0.7))
                    FieldBlock(label: "Check-Out", value: checkOut, align: .trailing, labelColor: roseMuted.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(red: 0.25, green: 0.05, blue: 0.1).opacity(0.45))

                // Guest / PIN
                HStack(alignment: .top) {
                    FieldBlock(label: "Guest / Reserved For", value: guest, labelColor: roseMuted.opacity(0.7))
                    FieldBlock(label: "Backup Door PIN", value: pin, align: .trailing, valueColor: roseMuted, labelColor: roseMuted.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                NFCUnlockFooter(
                    title: "Hold Near Door Lock to Unlock",
                    subtitle: "Apple VAS NFC Smart Door Access • Express Mode",
                    tint: rose
                )

                if !booking.isEmpty {
                    HStack {
                        Text("Confirmation")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(roseMuted)
                        Spacer()
                        Text(booking)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.35, green: 0.08, blue: 0.14)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.3, green: 0.06, blue: 0.12).opacity(0.6))
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.13, green: 0.07, blue: 0.09), Color(red: 0.07, green: 0.035, blue: 0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(rose.opacity(0.22), lineWidth: 1))
        }
    }
}

// MARK: - BookMyShow

private struct BookMyShowTicketCard: View {
    let fields: [String: String]
    private let pink = Color(red: 0.86, green: 0.15, blue: 0.35)

    var body: some View {
        let event = WalletPassPreview.value(fields, ["event"], fallback: "Movie")
        let venue = WalletPassPreview.value(fields, ["venue"], fallback: "—")
        let seat = WalletPassPreview.value(fields, ["seat"], fallback: "—")
        let time = WalletPassPreview.value(fields, ["time"], fallback: "—")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "—")

        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • EVENT_TICKET", right: "TURNSTILE QR", tint: pink)
            VStack(spacing: 0) {
                header(title: "BookMyShow", subtitle: "Cinema Ticket • IMAX 2D", icon: "ticket.fill", tint: pink)
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [Color(red: 0.4, green: 0.08, blue: 0.18), Color(red: 0.08, green: 0.04, blue: 0.08)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event).font(.title3.weight(.bold)).foregroundStyle(.white).lineLimit(2)
                        Text(venue).font(.subheadline).foregroundStyle(Color.white.opacity(0.75))
                    }
                    .padding(16)
                }
                .frame(height: 110)
                HStack {
                    FieldBlock(label: "Showtime", value: time)
                    FieldBlock(label: "Seats", value: seat, align: .trailing)
                }
                .padding(16)
                QRFooter(caption: "SCAN AT AUDI TURNSTILE", alt: booking)
            }
            .background(Color(red: 0.1, green: 0.05, blue: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(pink.opacity(0.25), lineWidth: 1))
        }
    }

    private func header(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack {
            HStack(spacing: 10) {
                Circle().fill(tint.opacity(0.2)).frame(width: 36, height: 36)
                    .overlay(Image(systemName: icon).foregroundStyle(tint))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline.weight(.bold)).foregroundStyle(.white)
                    Text(subtitle.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(tint.opacity(0.85)).tracking(0.6)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                MonoLabel(text: "Booking ID")
                Text(WalletPassPreview.value(fields, ["booking_id"], fallback: "—"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.white)
            }
        }
        .padding(16)
    }
}

// MARK: - District

private struct DistrictFestivalCard: View {
    let fields: [String: String]
    private let violet = Color(red: 0.55, green: 0.25, blue: 0.95)

    var body: some View {
        let event = WalletPassPreview.value(fields, ["event"], fallback: "Festival")
        let venue = WalletPassPreview.value(fields, ["venue"], fallback: "—")
        let tier = WalletPassPreview.value(fields, ["tier"], fallback: "GA")
        let gate = WalletPassPreview.value(fields, ["gate"], fallback: "—")
        let time = WalletPassPreview.value(fields, ["time"], fallback: "—")
        let booking = WalletPassPreview.value(fields, ["booking_id", "qr_data"], fallback: "—")

        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • EVENT_TICKET", right: "NFC WRISTBAND", tint: violet)
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("District").font(.headline.weight(.bold)).foregroundStyle(.white)
                        Text("FESTIVAL PASS • NFC WRISTBAND").font(.system(size: 10, weight: .bold)).foregroundStyle(violet).tracking(0.7)
                    }
                    Spacer()
                    Text(tier.uppercased())
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(violet))
                }
                .padding(16)
                VStack(alignment: .leading, spacing: 6) {
                    Text(event).font(.title3.weight(.bold)).foregroundStyle(.white)
                    Text(venue).font(.subheadline).foregroundStyle(Color.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.04))
                HStack {
                    FieldBlock(label: "Date & Gates", value: time)
                    FieldBlock(label: "Fast Entry", value: gate, align: .trailing)
                }
                .padding(16)
                NFCUnlockFooter(title: "Tap iPhone at Turnstile NFC Scanner", subtitle: "Apple VAS • Express Turnstile Entry", tint: violet)
                Text(booking)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.bottom, 14)
            }
            .background(Color(red: 0.08, green: 0.06, blue: 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(violet.opacity(0.3), lineWidth: 1))
        }
    }
}

// MARK: - IRCTC / Indigo boarding

private struct IRCTCRailCard: View {
    let fields: [String: String]
    private let blue = Color(red: 0.2, green: 0.55, blue: 0.9)

    var body: some View {
        boardingStyle(
            brand: "IRCTC",
            subtitle: "Indian Railways • e-Ticket",
            metaLeft: "PASSKIT • TRANSIT_PASS",
            metaRight: "INDIAN RAILWAYS QR",
            tint: blue,
            fromCode: abbreviate(WalletPassPreview.value(fields, ["origin"], fallback: "—")),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Origin"),
            toCode: abbreviate(WalletPassPreview.value(fields, ["destination"], fallback: "—")),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Destination"),
            headerLeft: ("Train", WalletPassPreview.value(fields, ["train"], fallback: "—")),
            headerRight: ("PNR Status", "CNF"),
            midLeft: ("Passenger", WalletPassPreview.value(fields, ["passenger", "name"], fallback: "—")),
            midRight: ("Coach / Berth", "\(WalletPassPreview.value(fields, ["coach"], fallback: "—")) / \(WalletPassPreview.value(fields, ["seat"], fallback: "—"))"),
            dep: WalletPassPreview.value(fields, ["dep", "time"], fallback: "—"),
            arr: WalletPassPreview.value(fields, ["arr"], fallback: "—"),
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "booking_id", "qr_data"], fallback: "")
        )
    }

    private func abbreviate(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 4 { return t.uppercased() }
        if let paren = t.split(separator: "(").last?.split(separator: ")").first, paren.count <= 4 {
            return String(paren).uppercased()
        }
        return String(t.prefix(3)).uppercased()
    }
}

private struct IndigoBoardingCard: View {
    let fields: [String: String]
    private let indigo = Color(red: 0.2, green: 0.15, blue: 0.55)

    var body: some View {
        boardingStyle(
            brand: "IndiGo",
            subtitle: "Boarding Pass",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: "AZTEC 2D",
            tint: Color(red: 0.45, green: 0.4, blue: 0.95),
            fromCode: WalletPassPreview.value(fields, ["origin"], fallback: "—").uppercased(),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Origin"),
            toCode: WalletPassPreview.value(fields, ["destination"], fallback: "—").uppercased(),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Destination"),
            headerLeft: ("Flight", WalletPassPreview.value(fields, ["flight"], fallback: "—")),
            headerRight: ("PNR", WalletPassPreview.value(fields, ["pnr", "booking_id"], fallback: "—")),
            midLeft: ("Passenger", WalletPassPreview.value(fields, ["passenger", "name"], fallback: "—")),
            midRight: ("Seat / Gate", "\(WalletPassPreview.value(fields, ["seat"], fallback: "—")) · \(WalletPassPreview.value(fields, ["gate"], fallback: "—"))"),
            dep: WalletPassPreview.value(fields, ["dep", "time"], fallback: "—"),
            arr: WalletPassPreview.value(fields, ["arr"], fallback: "—"),
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "qr_data"], fallback: "")
        )
    }
}

private func boardingStyle(
    brand: String,
    subtitle: String,
    metaLeft: String,
    metaRight: String,
    tint: Color,
    fromCode: String,
    fromName: String,
    toCode: String,
    toName: String,
    headerLeft: (String, String),
    headerRight: (String, String),
    midLeft: (String, String),
    midRight: (String, String),
    dep: String,
    arr: String,
    barcodeAlt: String
) -> some View {
    VStack(spacing: 10) {
        PassMetaChip(left: metaLeft, right: metaRight, tint: tint)
        VStack(spacing: 0) {
            Rectangle().fill(tint).frame(height: 6)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(brand).font(.headline.weight(.bold)).foregroundStyle(.white)
                    Text(subtitle.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(tint).tracking(0.6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    MonoLabel(text: headerLeft.0)
                    Text(headerLeft.1).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                }
            }
            .padding(16)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fromCode).font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                    Text(fromName).font(.caption).foregroundStyle(Color.white.opacity(0.65)).lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.right").foregroundStyle(tint).font(.title3.weight(.bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(toCode).font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                    Text(toName).font(.caption).foregroundStyle(Color.white.opacity(0.65)).lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            HStack {
                FieldBlock(label: "Depart", value: dep)
                FieldBlock(label: headerRight.0, value: headerRight.1, align: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            HStack {
                FieldBlock(label: midLeft.0, value: midLeft.1)
                FieldBlock(label: midRight.0, value: midRight.1, align: .trailing)
            }
            .padding(16)
            .background(Color.white.opacity(0.04))

            QRFooter(caption: "OFFICIAL SCANNER", alt: barcodeAlt)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(tint.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Metro / RedBus / Zoomcar / UPI / Dining

private struct NammaMetroCard: View {
    let fields: [String: String]
    private let purple = Color(red: 0.45, green: 0.2, blue: 0.75)
    var body: some View {
        let origin = WalletPassPreview.value(fields, ["origin"], fallback: "Origin")
        let dest = WalletPassPreview.value(fields, ["destination"], fallback: "Destination")
        let booking = WalletPassPreview.value(fields, ["booking_id", "qr_data"], fallback: "—")
        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • BOARDING_PASS", right: "BMRCL QR", tint: purple)
            VStack(spacing: 0) {
                HStack {
                    Text("Namma Metro").font(.headline.weight(.bold)).foregroundStyle(.white)
                    Spacer()
                    Text("PURPLE LINE").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(purple)
                }
                .padding(16)
                HStack {
                    FieldBlock(label: "Origin Station", value: origin)
                    Image(systemName: "tram.fill").foregroundStyle(purple)
                    FieldBlock(label: "Destination", value: dest, align: .trailing)
                }
                .padding(16)
                QRFooter(caption: "TOKEN / PASS ID", alt: booking)
            }
            .background(Color(red: 0.08, green: 0.06, blue: 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(purple.opacity(0.3), lineWidth: 1))
        }
    }
}

private struct RedBusCard: View {
    let fields: [String: String]
    private let red = Color(red: 0.85, green: 0.15, blue: 0.2)
    var body: some View {
        boardingStyle(
            brand: "redBus",
            subtitle: "Intercity Sleeper",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: "ON TIME",
            tint: red,
            fromCode: abbreviate(WalletPassPreview.value(fields, ["origin"], fallback: "BLR")),
            fromName: WalletPassPreview.value(fields, ["origin"], fallback: "Boarding"),
            toCode: abbreviate(WalletPassPreview.value(fields, ["destination"], fallback: "HYD")),
            toName: WalletPassPreview.value(fields, ["destination"], fallback: "Drop off"),
            headerLeft: ("Ticket PNR", WalletPassPreview.value(fields, ["pnr", "booking_id"], fallback: "—")),
            headerRight: ("Bus", WalletPassPreview.value(fields, ["bus"], fallback: "—")),
            midLeft: ("Passenger", WalletPassPreview.value(fields, ["passenger", "name"], fallback: "—")),
            midRight: ("Seat", WalletPassPreview.value(fields, ["seat"], fallback: "—")),
            dep: WalletPassPreview.value(fields, ["dep", "time"], fallback: "—"),
            arr: WalletPassPreview.value(fields, ["arr"], fallback: "—"),
            barcodeAlt: WalletPassPreview.value(fields, ["pnr", "qr_data"], fallback: "")
        )
    }
    private func abbreviate(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 4 { return t.uppercased() }
        return String(t.prefix(3)).uppercased()
    }
}

private struct ZoomcarKeylessCard: View {
    let fields: [String: String]
    private let green = Color(red: 0.15, green: 0.75, blue: 0.45)
    var body: some View {
        let vehicle = WalletPassPreview.value(fields, ["vehicle"], fallback: "Vehicle")
        let pickup = WalletPassPreview.value(fields, ["pickup"], fallback: "—")
        let drop = WalletPassPreview.value(fields, ["drop_off"], fallback: "—")
        let guest = WalletPassPreview.value(fields, ["guest"], fallback: "—")
        let booking = WalletPassPreview.value(fields, ["booking_id"], fallback: "—")
        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • GENERIC_KEYLESS", right: "KEYLESS SMARTLOCK", tint: green)
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zoomcar").font(.headline.weight(.bold)).foregroundStyle(.white)
                        Text("SELF-DRIVE RENTAL PASS").font(.system(size: 10, weight: .bold)).foregroundStyle(green).tracking(0.7)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        MonoLabel(text: "Key Status")
                        Text("READY TO UNLOCK").font(.system(size: 11, weight: .bold)).foregroundStyle(green)
                    }
                }
                .padding(16)
                Text(vehicle).font(.title3.weight(.bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                HStack {
                    FieldBlock(label: "Pickup & Unlock", value: pickup)
                    FieldBlock(label: "Drop Off & Lock", value: drop, align: .trailing)
                }
                .padding(16)
                NFCUnlockFooter(title: "Hold iPhone Near Windshield Reader", subtitle: "Backup PIN · Express Mode Active", tint: green)
                HStack {
                    FieldBlock(label: "Driver", value: guest)
                    FieldBlock(label: "Booking / PIN", value: booking, align: .trailing, valueColor: green)
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.1, blue: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(green.opacity(0.3), lineWidth: 1))
        }
    }
}

private struct UPIPayPassCard: View {
    let fields: [String: String]
    private let upi = Color(red: 0.2, green: 0.55, blue: 0.95)
    var body: some View {
        let name = WalletPassPreview.value(fields, ["name"], fallback: "Payee")
        let vpa = WalletPassPreview.value(fields, ["vpa", "qr_data"], fallback: "—")
        let bank = WalletPassPreview.value(fields, ["bank"], fallback: "—")
        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • STORE_CARD", right: "NPCI 2.0", tint: upi)
            VStack(spacing: 0) {
                HStack {
                    Text("UPI PayPass").font(.headline.weight(.bold)).foregroundStyle(.white)
                    Spacer()
                    Text("ACTIVE VPA").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Color.green)
                }
                .padding(16)
                FieldBlock(label: "Account Holder", value: name)
                    .padding(.horizontal, 16)
                HStack {
                    FieldBlock(label: "VPA", value: vpa)
                    FieldBlock(label: "Linked Bank", value: bank, align: .trailing)
                }
                .padding(16)
                QRFooter(caption: "SCAN TO PAY", alt: vpa)
            }
            .background(Color(red: 0.06, green: 0.1, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(upi.opacity(0.3), lineWidth: 1))
        }
    }
}

private struct EazyDinerPrimeCard: View {
    let fields: [String: String]
    private let gold = Color(red: 0.85, green: 0.65, blue: 0.25)
    var body: some View {
        diningCard(
            brand: "EazyDiner",
            subtitle: "VIP Culinary Pass",
            meta: ("PASSKIT • STORE_CARD", "VIP PRIME"),
            tint: gold,
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size", "guest"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "SCAN AT BILL SETTLEMENT"
        )
    }
}

private struct ZomatoDiningCard: View {
    let fields: [String: String]
    private let red = Color(red: 0.9, green: 0.2, blue: 0.25)
    var body: some View {
        diningCard(
            brand: "Zomato",
            subtitle: "Table Reservation • Confirmed",
            meta: ("PASSKIT • EVENT_TICKET", "PODIUM BEACON"),
            tint: red,
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "SHOW AT HOSTESS PODIUM"
        )
    }
}

private struct SwiggyDineoutCard: View {
    let fields: [String: String]
    private let orange = Color(red: 0.95, green: 0.45, blue: 0.15)
    var body: some View {
        diningCard(
            brand: "Swiggy Dineout",
            subtitle: "Dining Coupon & Bill Pay",
            meta: ("PASSKIT • COUPON", "CODE 128"),
            tint: orange,
            restaurant: WalletPassPreview.value(fields, ["restaurant"], fallback: "Restaurant"),
            time: WalletPassPreview.value(fields, ["time"], fallback: "—"),
            guests: WalletPassPreview.value(fields, ["party_size"], fallback: "—"),
            booking: WalletPassPreview.value(fields, ["booking_id"], fallback: "—"),
            footer: "SCAN OR PRESENT TO SERVER"
        )
    }
}

private func diningCard(
    brand: String,
    subtitle: String,
    meta: (String, String),
    tint: Color,
    restaurant: String,
    time: String,
    guests: String,
    booking: String,
    footer: String
) -> some View {
    VStack(spacing: 10) {
        PassMetaChip(left: meta.0, right: meta.1, tint: tint)
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(brand).font(.headline.weight(.bold)).foregroundStyle(.white)
                    Text(subtitle.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(tint).tracking(0.6)
                }
                Spacer()
            }
            .padding(16)
            Text(restaurant)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            HStack {
                FieldBlock(label: "Date & Slot", value: time)
                FieldBlock(label: "Party", value: guests, align: .trailing)
            }
            .padding(16)
            QRFooter(caption: footer, alt: booking)
        }
        .background(Color(red: 0.08, green: 0.06, blue: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(tint.opacity(0.28), lineWidth: 1))
    }
}

private struct GenericStitchCard: View {
    let brandId: String
    let displayName: String
    let fields: [String: String]
    var accentRGB: String? = nil

    var body: some View {
        let tint = SlipTheme.color(fromRGB: accentRGB) ?? SlipTheme.accent
        VStack(spacing: 10) {
            PassMetaChip(left: "PASSKIT • GENERIC", right: brandId.uppercased(), tint: tint)
            VStack(alignment: .leading, spacing: 12) {
                Text(displayName).font(.headline.weight(.bold)).foregroundStyle(.white)
                ForEach(Array(fields.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }.prefix(6)), id: \.key) { key, value in
                    FieldBlock(label: key.replacingOccurrences(of: "_", with: " "), value: value)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
