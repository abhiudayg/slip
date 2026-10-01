import SwiftUI

struct AirbnbRoomKeyCard: View {
    @Binding var fields: [String: String]
    var editable: Bool = true
    private let p = PassPalettes.airbnb

    var body: some View {
        let property = PassFieldBag.value(fields, ["property"], fallback: "Villa Sol • Candolim Beach")
        let propertyType = PassFieldBag.value(fields, ["property_type"], fallback: "Entire Coastal Villa")
        let address = PassFieldBag.value(fields, ["address", "city"], fallback: "Goa, India")
        let checkInDate = PassFieldBag.value(fields, ["check_in"], fallback: "Thu, 24 Oct")
        let checkInTime = PassFieldBag.value(fields, ["check_in_time"], fallback: "14:00 onwards")
        let checkOutDate = PassFieldBag.value(fields, ["check_out"], fallback: "Mon, 28 Oct")
        let checkOutTime = PassFieldBag.value(fields, ["check_out_time"], fallback: "11:00 am")
        let guest = {
            let g = PassFieldBag.value(fields, ["guest"], fallback: "—")
            let d = PassFieldBag.value(fields, ["guest_details"], fallback: "")
            return d.isEmpty || d == "—" ? g : "\(g)\n\(d)"
        }()
        // Never fall back to booking_id — that made the PIN look stuck on the confirmation code.
        let pin = PassFieldBag.value(fields, ["door_pin"], fallback: "4 8 2 9 #")
        let booking = PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "")
        let wifi = PassFieldBag.value(fields, ["wifi_ssid"], fallback: "")
        let wifiPass = PassFieldBag.value(fields, ["wifi_password"], fallback: "")
        let status = PassFieldBag.value(fields, ["status"], fallback: "ACTIVE")
        let host = PassFieldBag.value(fields, ["host"], fallback: "")
        let hostBadge = PassFieldBag.value(fields, ["host_badge"], fallback: "")
        let lockBrand = PassFieldBag.value(fields, ["lock_brand"], fallback: "")

        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC_KEYLESS", right: "APPLE VAS NFC", tint: p.accent)
            EventTicketShell(palette: p, appIcon: "house.fill") {
                VStack(spacing: 0) {
                    EventTicketHeader(
                        title: "Airbnb",
                        subtitle: "Room Key & Access",
                        topLeftLogo: nil,
                        rightText1: "Key Status",
                        rightText2: status.uppercased().hasPrefix("●") ? status.uppercased() : "● \(status.uppercased())",
                        brandColor: Color(red: 1.0, green: 0.35, blue: 0.45)
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(
                        title: property,
                        badge: {
                            let badge = PassFieldBag.pair(propertyType, hostBadge)
                            return badge.isEmpty ? nil : badge
                        }(),
                        trailing: nil,
                        palette: p,
                        height: 124,
                        titleBinding: editable ? fieldBinding("property") : nil,
                        thumbnailImage: "bed.double.fill"
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
                    if !booking.isEmpty {
                        TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                        QRPanel(caption: "Booking Confirmation", alt: booking, accent: p.accentSoft)
                    } else {
                        NFCPanel(
                        title: "Hold Near Door Lock to Unlock",
                        subtitle: "Apple VAS NFC • Details on back",
                        tint: p.accent
                    )
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

struct EditableFieldBlock: View {
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

struct BookMyShowTicketCard: View {
    let fields: [String: String]
    private let p = PassPalettes.bms

    var body: some View {
        let model = EventFaceModel.bookmyshow(fields)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • EVENT_TICKET", right: "TURNSTILE QR", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "BookMyShow",
                        subtitle: "Cinema Ticket",
                        logo: LogoTile(systemImage: "ticket.fill", colors: [p.accent, Color(red: 0.6, green: 0.05, blue: 0.2)]),
                        trailingLabel: "Booking ID",
                        trailingValue: model.booking,
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: model.title, badge: model.badge, trailing: nil, palette: p)
                    VStack(alignment: .leading, spacing: 4) {
                        MonoLabel(text: "Cinema", color: p.accentSoft.opacity(0.7))
                        Text(model.venueLine)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(p.accent.opacity(0.08))
                    HStack(spacing: 10) {
                        fieldChip("Showtime", model.whenLine, p)
                        fieldChip("Seats", model.seatLine, p)
                    }
                    .padding(14)
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan at audi turnstile", alt: model.booking, accent: p.accentSoft)
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

struct DistrictFestivalCard: View {
    let fields: [String: String]
    private let p = PassPalettes.district
    var body: some View {
        let model = EventFaceModel.district(fields)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • EVENT_TICKET", right: "NFC WRISTBAND", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "District",
                        subtitle: "Festival Pass · NFC Wristband",
                        logo: LogoTile(systemImage: "bolt.fill", colors: [p.accent, Color(red: 0.3, green: 0.1, blue: 0.6)]),
                        trailingLabel: "Tier",
                        trailingValue: (model.badge ?? "VIP").uppercased(),
                        accentSoft: p.accentSoft,
                        trailingColor: p.accentSoft
                    )
                    StripHero(title: model.title, badge: "Live Arena", trailing: nil, palette: p, height: 110)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.venueLine).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
                    HStack {
                        FieldBlock(label: "Date & Gates", value: model.whenLine, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Fast Entry", value: model.seatLine, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    SoftDivider(tint: p.accent.opacity(0.1))
                    HStack {
                        FieldBlock(label: "Wristband ID", value: model.booking, labelColor: p.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.06))
                    NFCPanel(title: "Tap iPhone at Turnstile NFC Scanner", subtitle: "More details on back · \(model.booking)", tint: p.accent)
                }
            }
        }
    }
}

struct DiningShell: View {
    let brand: String
    let subtitle: String
    let meta: (String, String)
    let palette: PassPalette
    let logoColors: [Color]
    let restaurant: String
    let headerLeft: (String, String)
    let headerRight: (String, String)?
    let midLeft: (String, String)?
    let midRight: (String, String)?
    let extraLeft: (String, String)?
    let extraRight: (String, String)?
    let booking: String
    let footer: String
    var badge: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            PassMetaBar(left: meta.0, right: meta.1, tint: palette.accent)
            EventTicketShell(palette: palette, appIcon: "fork.knife") {
                VStack(spacing: 0) {
                    EventTicketHeader(
                        title: brand,
                        subtitle: subtitle,
                        topLeftLogo: nil,
                        rightText1: headerLeft.0,
                        rightText2: headerLeft.1,
                        brandColor: .white
                    )
                    SoftDivider(tint: palette.accent.opacity(0.12))
                    StripHero(
                        title: restaurant, 
                        badge: badge, 
                        palette: palette, 
                        height: 118,
                        thumbnailImage: "wineglass.fill"
                    )
                    
                    if let hr = headerRight {
                        HStack {
                            FieldBlock(label: hr.0, value: hr.1, labelColor: palette.accentSoft.opacity(0.7))
                            if let ml = midLeft {
                                FieldBlock(label: ml.0, value: ml.1, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                            }
                        }
                        .padding(16)
                    }
                    
                    if let mr = midRight, let el = extraLeft {
                        SoftDivider(tint: palette.accent.opacity(0.1))
                        HStack {
                            FieldBlock(label: mr.0, value: mr.1, labelColor: palette.accentSoft.opacity(0.7))
                            FieldBlock(label: el.0, value: el.1, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                        }
                        .padding(16)
                    }
                    
                    if let er = extraRight {
                        HStack {
                            FieldBlock(label: er.0, value: er.1, labelColor: palette.accentSoft.opacity(0.7))
                            FieldBlock(label: "Booking", value: booking, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                        }
                        .padding(16)
                        .background(palette.accent.opacity(0.08))
                    } else {
                        HStack {
                            FieldBlock(label: "Booking", value: booking, labelColor: palette.accentSoft.opacity(0.7))
                            Spacer()
                        }
                        .padding(16)
                        .background(palette.accent.opacity(0.08))
                    }
                    
                    SoftDivider(tint: palette.accent.opacity(0.12))
                    QRPanel(caption: footer, alt: booking, accent: palette.accentSoft)
                }
            }
        }
    }
}

struct EazyDinerPrimeCard: View {
    let fields: [String: String]
    var body: some View {
        let model = DiningFaceModel.easydiner(fields)
        let status = PassFieldBag.value(fields, ["status"], fallback: "VIP PRIME")
        DiningShell(
            brand: "EazyDiner",
            subtitle: "VIP Culinary Pass",
            meta: ("PASSKIT • STORE_CARD", status.uppercased()),
            palette: PassPalettes.easydiner,
            logoColors: [PassPalettes.easydiner.accent, Color(red: 0.7, green: 0.4, blue: 0.05)],
            restaurant: model.restaurant,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            booking: model.booking,
            footer: model.footer,
            badge: model.badge
        )
    }
}

struct ZomatoDiningCard: View {
    let fields: [String: String]
    var body: some View {
        let model = DiningFaceModel.zomato(fields)
        DiningShell(
            brand: "Zomato",
            subtitle: "Table Reservation · Confirmed",
            meta: ("PASSKIT • EVENT_TICKET", "PODIUM BEACON"),
            palette: PassPalettes.zomato,
            logoColors: [PassPalettes.zomato.accent, Color(red: 0.6, green: 0.05, blue: 0.12)],
            restaurant: model.restaurant,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            booking: model.booking,
            footer: model.footer,
            badge: model.badge
        )
    }
}

struct SwiggyDineoutCard: View {
    let fields: [String: String]
    var body: some View {
        let model = DiningFaceModel.swiggy(fields)
        DiningShell(
            brand: "Swiggy Dineout",
            subtitle: "Dining Coupon & Bill Pay",
            meta: ("PASSKIT • COUPON", "CODE 128"),
            palette: PassPalettes.swiggy,
            logoColors: [PassPalettes.swiggy.accent, Color(red: 0.85, green: 0.3, blue: 0.05)],
            restaurant: model.restaurant,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            booking: model.booking,
            footer: model.footer,
            badge: model.badge
        )
    }
}

struct BoardingCard: View {
    let brand: String
    let subtitle: String
    let metaLeft: String
    let metaRight: String
    let palette: PassPalette
    let logo: LogoTile
    let fromCode: String
    let fromName: String
    var fromDesc: String? = nil
    let toCode: String
    let toName: String
    var toDesc: String? = nil
    let headerLeft: (String, String)
    let headerRight: (String, String)
    let midLeft: (String, String)
    let midRight: (String, String)
    var extraLeft: (String, String)? = nil
    var extraRight: (String, String)? = nil
    var footer: String? = nil
    let duration: String
    let routeIcon: String
    let barcodeAlt: String
    let barcodeCaption: String

    var body: some View {
        VStack(spacing: 12) {
            PassMetaBar(left: metaLeft, right: metaRight, tint: palette.accent)
            PassShell(palette: palette, appIcon: routeIcon) {
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
                            if let fromDesc {
                                Text(fromDesc).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(palette.accentSoft)
                            }
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
                            if let toDesc {
                                Text(toDesc).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(palette.accentSoft)
                            }
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
                    .padding(.top, 12)
                    .padding(.bottom, extraLeft == nil ? 12 : 4)

                    if let el = extraLeft, let er = extraRight {
                        HStack {
                            FieldBlock(label: el.0, value: el.1, labelColor: palette.accentSoft.opacity(0.7))
                            FieldBlock(label: er.0, value: er.1, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                    }

                    SoftDivider(tint: palette.accent.opacity(0.1))

                    HStack {
                        FieldBlock(label: midRight.0, value: midRight.1, labelColor: palette.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    
                    if let footer {
                        Text(footer)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(palette.accentSoft.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 10)
                    }

                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: barcodeCaption, alt: barcodeAlt, accent: palette.accentSoft)
                }
            }
        }
    }
}

struct IRCTCRailCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.irctc
        let model = BoardingFaceModel.irctc(fields)
        BoardingCard(
            brand: "IRCTC",
            subtitle: "Indian Railways · e-Ticket",
            metaLeft: "PASSKIT • TRANSIT_PASS",
            metaRight: PassFieldBag.value(fields, ["pnr_status"], fallback: "CNF / CONFIRMED"),
            palette: p,
            logo: LogoTile(systemImage: "train.side.front.car", colors: [p.accent, Color(red: 0.85, green: 0.5, blue: 0.05)], glyphColor: Color(red: 0.08, green: 0.08, blue: 0.1)),
            fromCode: model.fromCode,
            fromName: model.fromName,
            fromDesc: model.fromDesc,
            toCode: model.toCode,
            toName: model.toName,
            toDesc: model.toDesc,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            footer: model.footer,
            duration: model.duration,
            routeIcon: "train.side.front.car",
            barcodeAlt: model.barcodeAlt,
            barcodeCaption: model.barcodeCaption
        )
    }
}

struct IndigoBoardingCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.indigo
        let model = BoardingFaceModel.indigo(fields)
        BoardingCard(
            brand: "IndiGo",
            subtitle: "Boarding Pass",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: PassFieldBag.value(fields, ["status"], fallback: "AZTEC 2D"),
            palette: p,
            logo: LogoTile(systemImage: "airplane", colors: [p.accent, Color(red: 0.1, green: 0.25, blue: 0.7)]),
            fromCode: model.fromCode,
            fromName: model.fromName,
            fromDesc: model.fromDesc,
            toCode: model.toCode,
            toName: model.toName,
            toDesc: model.toDesc,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            footer: model.footer,
            duration: model.duration,
            routeIcon: "airplane",
            barcodeAlt: model.barcodeAlt,
            barcodeCaption: model.barcodeCaption
        )
    }
}

struct RedBusCard: View {
    let fields: [String: String]
    var body: some View {
        let p = PassPalettes.redbus
        let model = BoardingFaceModel.redbus(fields)
        BoardingCard(
            brand: "redBus",
            subtitle: "Intercity Sleeper",
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: "ON TIME",
            palette: p,
            logo: LogoTile(systemImage: "bus.fill", colors: [p.accent, Color(red: 0.6, green: 0.05, blue: 0.08)]),
            fromCode: model.fromCode,
            fromName: model.fromName,
            fromDesc: model.fromDesc,
            toCode: model.toCode,
            toName: model.toName,
            toDesc: model.toDesc,
            headerLeft: model.headerLeft,
            headerRight: model.headerRight,
            midLeft: model.midLeft,
            midRight: model.midRight,
            extraLeft: model.extraLeft,
            extraRight: model.extraRight,
            footer: model.footer,
            duration: model.duration,
            routeIcon: "bus.fill",
            barcodeAlt: model.barcodeAlt,
            barcodeCaption: model.barcodeCaption
        )
    }
}

struct NammaMetroCard: View {
    let fields: [String: String]
    private let p = PassPalettes.metro
    var body: some View {
        let model = MetroFaceModel.namma(fields)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • BOARDING_PASS", right: model.line, tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Namma Metro",
                        subtitle: "BMRCL Rapid Transit",
                        logo: LogoTile(systemImage: "tram.fill", colors: [p.accent, Color(red: 0.3, green: 0.1, blue: 0.55)]),
                        trailingLabel: "Ticket Type",
                        trailingValue: model.ticketType,
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Origin Station", value: model.origin, labelColor: p.accentSoft.opacity(0.7), valueSize: 17)
                        RouteConnector(duration: model.routeMeta.isEmpty ? "Metro" : model.routeMeta, tint: p.accent, icon: "tram.fill")
                        FieldBlock(label: "Destination", value: model.destination, align: .trailing, labelColor: p.accentSoft.opacity(0.7), valueSize: 17)
                    }
                    .padding(18)
                    SoftDivider(tint: p.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Valid Till", value: model.validTill, labelColor: p.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.05))
                    if !model.passenger.isEmpty && model.passenger != "—" {
                        HStack {
                            FieldBlock(label: "Passenger", value: model.passenger, labelColor: p.accentSoft.opacity(0.7))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Token / Pass ID", alt: model.booking, accent: p.accentSoft)
                }
            }
        }
    }
}

struct ZoomcarKeylessCard: View {
    let fields: [String: String]
    private let p = PassPalettes.zoomcar
    var body: some View {
        let model = KeylessFaceModel.zoomcar(fields)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC_KEYLESS", right: "KEYLESS SMARTLOCK", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Zoomcar",
                        subtitle: "Self-Drive Rental Pass",
                        logo: LogoTile(systemImage: "car.fill", colors: [p.accent, Color(red: 0.2, green: 0.55, blue: 0.15)], glyphColor: Color(red: 0.05, green: 0.08, blue: 0.03)),
                        trailingLabel: "Key Status",
                        trailingValue: model.status.uppercased(),
                        accentSoft: p.accentSoft,
                        trailingColor: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: model.title, badge: model.subtitleBadge, palette: p, height: 112)
                    HStack {
                        FieldBlock(label: "Registration", value: model.primaryLeft.1, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Backup PIN", value: model.tertiaryLeft.1, align: .trailing, valueColor: p.accentSoft, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    SoftDivider(tint: p.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Pickup", value: model.secondaryLeft.1, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Drop Off", value: model.secondaryRight.1, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.06))
                    NFCPanel(title: model.nfcTitle, subtitle: "More details on back", tint: p.accent)
                    if !model.booking.isEmpty {
                        HStack {
                            FieldBlock(label: "Booking", value: model.booking, labelColor: p.accentSoft.opacity(0.7))
                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
        }
    }
}

struct UPIPayPassCard: View {
    let fields: [String: String]
    private let p = PassPalettes.upi
    var body: some View {
        let model = UPIFaceModel.from(fields)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • STORE_CARD", right: "NPCI 2.0", tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "UPI PayPass",
                        subtitle: "Instant Receive & Pay",
                        logo: LogoTile(systemImage: "qrcode", colors: [p.accent, Color(red: 0.1, green: 0.3, blue: 0.7)]),
                        trailingLabel: "Status",
                        trailingValue: model.status.uppercased(),
                        accentSoft: p.accentSoft,
                        trailingColor: Color(red: 0.3, green: 0.9, blue: 0.55)
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Account Holder", value: model.name, labelColor: p.accentSoft.opacity(0.7), valueSize: 18)
                        FieldBlock(label: "VPA", value: model.vpa, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    HStack {
                        FieldBlock(label: "Linked Bank", value: model.bank, labelColor: p.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.05))
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan to pay via any UPI app", alt: model.vpa, accent: p.accentSoft)
                }
            }
        }
    }
}

struct CultAccessCard: View {
    let fields: [String: String]
    var body: some View {
        let model = MembershipFaceModel.cult(fields)
        let p = PassPalettes.cult
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • STORE_CARD", right: model.status.uppercased(), tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Cult.fit",
                        subtitle: model.membership,
                        logo: LogoTile(systemImage: "figure.run", colors: [p.accent, Color(red: 0.7, green: 0.1, blue: 0.2)]),
                        trailingLabel: "Plan",
                        trailingValue: model.plan,
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: model.center, badge: "Gym Access", palette: p, height: 110)
                    HStack {
                        FieldBlock(label: "Member", value: model.name, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Valid Thru", value: model.validThru, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    HStack {
                        FieldBlock(label: "Member ID", value: model.memberId, labelColor: p.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.06))
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan at entrance", alt: model.booking, accent: p.accentSoft)
                }
            }
        }
    }
}

struct GoldsGymAccessCard: View {
    let fields: [String: String]
    var body: some View {
        let model = MembershipFaceModel.golds(fields)
        let p = PassPalettes.golds
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • STORE_CARD", right: model.status.uppercased(), tint: p.accent)
            PassShell(palette: p) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: "Gold's Gym",
                        subtitle: model.membership,
                        logo: LogoTile(systemImage: "dumbbell.fill", colors: [p.accent, Color(red: 0.6, green: 0.45, blue: 0.1)]),
                        trailingLabel: "Plan",
                        trailingValue: model.plan,
                        accentSoft: p.accentSoft
                    )
                    SoftDivider(tint: p.accent.opacity(0.12))
                    StripHero(title: model.center, badge: "Club Access", palette: p, height: 110)
                    HStack {
                        FieldBlock(label: "Member", value: model.name, labelColor: p.accentSoft.opacity(0.7))
                        FieldBlock(label: "Valid Thru", value: model.validThru, align: .trailing, labelColor: p.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    HStack {
                        FieldBlock(label: "Member ID", value: model.memberId, labelColor: p.accentSoft.opacity(0.7))
                        Spacer()
                    }
                    .padding(16)
                    .background(p.accent.opacity(0.06))
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan at turnstile", alt: model.booking, accent: p.accentSoft)
                }
            }
        }
    }
}

struct RideHailingCard: View {
    let brand: String
    let fields: [String: String]
    let palette: PassPalette
    var body: some View {
        let model = RideFaceModel.ride(fields, fallbackService: brand == "uber" ? "Uber Premier" : "Ola Outstation")
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • GENERIC", right: model.status.uppercased(), tint: palette.accent)
            PassShell(palette: palette) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: brand == "uber" ? "Uber" : "Ola",
                        subtitle: model.service,
                        logo: LogoTile(systemImage: "car.fill", colors: [palette.accent, palette.accent.opacity(0.5)]),
                        trailingLabel: "PIN",
                        trailingValue: model.pin,
                        accentSoft: palette.accentSoft,
                        trailingColor: palette.accentSoft
                    )
                    SoftDivider(tint: palette.accent.opacity(0.12))
                    HStack {
                        FieldBlock(label: "Pickup", value: model.pickup, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "Drop", value: model.drop, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    HStack {
                        FieldBlock(label: "Vehicle", value: model.vehicle, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "ETA", value: model.eta, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    .background(palette.accent.opacity(0.06))
                    HStack {
                        FieldBlock(label: "Driver", value: model.driver, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "Booking", value: model.booking, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Show to driver", alt: model.booking, accent: palette.accentSoft)
                }
            }
        }
    }
}

struct RetailLoyaltyCard: View {
    let brandTitle: String
    let fields: [String: String]
    let palette: PassPalette
    let systemImage: String
    var body: some View {
        let model = RetailFaceModel.loyalty(fields, fallbackStore: brandTitle)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASSKIT • STORE_CARD", right: model.tier.uppercased(), tint: palette.accent)
            PassShell(palette: palette) {
                VStack(spacing: 0) {
                    BrandHeaderRow(
                        title: brandTitle,
                        subtitle: "Loyalty & Offers",
                        logo: LogoTile(systemImage: systemImage, colors: [palette.accent, palette.accent.opacity(0.55)]),
                        trailingLabel: "Offer",
                        trailingValue: model.offer,
                        accentSoft: palette.accentSoft
                    )
                    SoftDivider(tint: palette.accent.opacity(0.12))
                    StripHero(title: model.store, badge: model.code.isEmpty ? nil : model.code, palette: palette, height: 100)
                    HStack {
                        FieldBlock(label: "Member", value: model.member, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "Points", value: model.points.isEmpty ? "—" : model.points, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    HStack {
                        FieldBlock(label: "Valid", value: model.valid.isEmpty ? "—" : model.valid, labelColor: palette.accentSoft.opacity(0.7))
                        FieldBlock(label: "ID", value: model.booking, align: .trailing, labelColor: palette.accentSoft.opacity(0.7))
                    }
                    .padding(16)
                    .background(palette.accent.opacity(0.06))
                    TicketNotchDivider(bg: Color(red: 0.07, green: 0.08, blue: 0.12))
                    QRPanel(caption: "Scan at billing", alt: model.booking, accent: palette.accentSoft)
                }
            }
        }
    }
}

struct TravelOTACard: View {
    let brandTitle: String
    let fields: [String: String]
    let palette: PassPalette
    var body: some View {
        // Reuse boarding face extraction for flight/hotel OTAs.
        let origin = PassFieldBag.value(fields, ["origin"], fallback: "BLR")
        let dest = PassFieldBag.value(fields, ["destination"], fallback: "GOI")
        BoardingCard(
            brand: brandTitle,
            subtitle: PassFieldBag.value(fields, ["trip_type", "service"], fallback: "Trip Pass"),
            metaLeft: "PASSKIT • BOARDING_PASS",
            metaRight: PassFieldBag.value(fields, ["status"], fallback: "CONFIRMED"),
            palette: palette,
            logo: LogoTile(systemImage: "suitcase.fill", colors: [palette.accent, palette.accent.opacity(0.5)]),
            fromCode: PassFieldBag.abbreviate(origin),
            fromName: origin,
            fromDesc: PassFieldBag.value(fields, ["origin_terminal", "boarding_point"], fallback: ""),
            toCode: PassFieldBag.abbreviate(dest),
            toName: dest,
            toDesc: PassFieldBag.value(fields, ["dest_terminal", "drop_point"], fallback: ""),
            headerLeft: ("PNR", PassFieldBag.value(fields, ["pnr", "booking_id"], fallback: "MMT-10293")),
            headerRight: ("Depart", PassFieldBag.pair(
                PassFieldBag.value(fields, ["date"], fallback: ""),
                PassFieldBag.value(fields, ["dep", "time"], fallback: "08:40")
            )),
            midLeft: ("Arrive", PassFieldBag.value(fields, ["arr"], fallback: "—")),
            midRight: ("Traveler", PassFieldBag.value(fields, ["passenger", "guest"], fallback: "Rohit Kumar")),
            extraLeft: ("Flight / Stay", PassFieldBag.value(fields, ["flight", "property", "train"], fallback: "—")),
            extraRight: ("Seat / Room", PassFieldBag.value(fields, ["seat", "room"], fallback: "—")),
            footer: PassFieldBag.value(fields, ["note"], fallback: "Show at check-in counter"),
            duration: PassFieldBag.value(fields, ["duration"], fallback: "—"),
            routeIcon: "airplane",
            barcodeAlt: PassFieldBag.value(fields, ["pnr", "booking_id", "qr_data"], fallback: "OTA-1001"),
            barcodeCaption: "Booking QR"
        )
    }
}

struct GenericStitchCard: View {
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
                    ForEach(Array(fields.filter {
                        let k = $0.key
                        let v = $0.value.trimmingCharacters(in: .whitespaces)
                        return !v.isEmpty && !["location", "latitude", "longitude", "qr_data"].contains(k)
                    }.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        FieldBlock(label: key.replacingOccurrences(of: "_", with: " "), value: value, labelColor: tint.opacity(0.7))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
