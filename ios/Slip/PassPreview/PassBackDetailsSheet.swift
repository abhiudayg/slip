import SwiftUI
import UIKit

/// Stitch-faithful Apple Wallet Back-of-Pass Details Sheet
/// Recreates the full back page screen for all brands:
/// - pass_details_passbackview_info_sheet
/// - pass_details_airbnb_key_flip_info_sheet
/// - pass_details_bookmyshow_flip_info_sheet
/// - pass_details_uber_ride_flip_info_sheet
struct PassBackDetailsSheet: View {
    let brandId: String
    let brandTitle: String
    let fields: [String: String]
    var vaultRecordId: String? = nil
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var automaticUpdates = true
    @State private var suggestOnLockScreen = true
    @State private var liveActivityEnabled = true
    @State private var showDeleteConfirmation = false
    @State private var copiedNotice: String? = nil

    private var palette: PassPalette {
        PassPalettes.resolved(templateId: brandId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Pass Identity Summary Card
                        PassBackHeroCard(
                            brandId: brandId,
                            brandTitle: brandTitle,
                            fields: fields,
                            palette: palette
                        )

                        // Brand-tailored specialized logistics & policy blocks
                        brandSpecificContent

                        // Native iOS-style system integration toggles
                        systemBehaviorsSection

                        // Ecosystem & pass sharing actions
                        passActionsSection

                        // Destructive remove pass section
                        destructiveActionSection

                        // Cryptographic security footer
                        cryptographicFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.accentSoft)
                        Text("Pass Details")
                            .font(SlipTheme.headline(size: 17, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(SlipTheme.glassSurface)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                        )
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if let notice = copiedNotice {
                    Text(notice)
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.85)).overlay(Capsule().strokeBorder(palette.accent.opacity(0.4), lineWidth: 1)))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
            .alert("Remove Pass?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Removing will erase the cryptographic NFC key from local Secure Enclave.")
            }
        }
    }

    // MARK: - Brand-Specific Specialized Content

    @ViewBuilder
    private var brandSpecificContent: some View {
        switch brandId {
        case "airbnb":
            AirbnbBackContent(fields: fields, palette: palette, onCopy: triggerCopy)
        case "bookmyshow", "district":
            BookMyShowBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        case "uber", "ola", "zoomcar":
            MobilityBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        case "irctc", "uts":
            IRCTCBackContent(fields: fields, palette: palette, onCopy: triggerCopy)
        case "indigo", "makemytrip", "cleartrip", "yatra":
            FlightBackContent(fields: fields, palette: palette, onCopy: triggerCopy)
        case "namma-metro", "redbus", "chalo":
            TransitBusMetroBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        case "zomato-dineout", "swiggy-dineout", "easydiner":
            DiningBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        case "cult", "golds-gym":
            FitnessBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        case "tata-neu", "reliance-smart", "shoppers-stop", "bigbasket":
            RetailLoyaltyBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        default:
            GenericBackContent(brandId: brandId, fields: fields, palette: palette, onCopy: triggerCopy)
        }
    }

    // MARK: - System Behaviors / Toggles Section

    private var systemBehaviorsSection: some View {
        VStack(spacing: 0) {
            PassBackToggleRow(
                title: "Automatic Updates",
                subtitle: "Keep pass time, gate changes, and live status synchronized via Push Notification.",
                isOn: $automaticUpdates
            )
            SoftDivider(tint: Color.white.opacity(0.06))
            PassBackToggleRow(
                title: "Suggest on Lock Screen",
                subtitle: "Geofencing triggers pass suggestion near perimeter based on location.",
                isOn: $suggestOnLockScreen
            )
            if brandId == "uber" || brandId == "ola" || brandId == "indigo" || brandId == "irctc" || brandId == "bookmyshow" {
                SoftDivider(tint: Color.white.opacity(0.06))
                PassBackToggleRow(
                    title: "Live Activity & Dynamic Island",
                    subtitle: "Real-time route, seat status & pickup alerts on Lock Screen.",
                    isOn: $liveActivityEnabled
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
        )
    }

    // MARK: - Pass Actions Section

    private var passActionsSection: some View {
        VStack(spacing: 0) {
            if let shareUrl = URL(string: "https://slip.app/pass/\(vaultRecordId ?? brandId)") {
                ShareLink(item: shareUrl) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SlipTheme.accentSoft)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                        Text("Share Pass via AirDrop")
                            .font(SlipTheme.body(size: 15, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }

            if UPIPayLink.canPay(fields: fields) {
                SoftDivider(tint: Color.white.opacity(0.06))
                Button {
                    UPIPayLink.open(fields: fields)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                        Text("Pay Bill with UPI")
                            .font(SlipTheme.body(size: 15, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
        )
    }

    // MARK: - Destructive Action Section

    private var destructiveActionSection: some View {
        VStack(spacing: 6) {
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Remove Pass")
                        .font(SlipTheme.headline(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.red.opacity(0.25), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            Text("Removing will erase the cryptographic NFC key from local Secure Enclave.")
                .font(SlipTheme.labelMono())
                .foregroundStyle(SlipTheme.muted.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 4)
    }

    // MARK: - Cryptographic Signature Footer

    private var cryptographicFooter: some View {
        let serial = vaultRecordId ?? "SLIP-\(brandId.uppercased())-\(fields["pnr"] ?? fields["booking_id"] ?? "894102")"
        return VStack(spacing: 4) {
            Text("SERIAL: \(serial)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(SlipTheme.muted.opacity(0.8))
                .tracking(1.2)
            Text("SHA-256: 8f3c...b09e • Signed by \(brandTitle) CA")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(SlipTheme.muted.opacity(0.5))
            Text("Powered by Slip SecurePass™ VAS 2.0")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(palette.accentSoft.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func triggerCopy(text: String, label: String) {
        UIPasteboard.general.string = text
        SlipHaptics.scrollTick()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            copiedNotice = "Copied \(label)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                if copiedNotice == "Copied \(label)" {
                    copiedNotice = nil
                }
            }
        }
    }
}

// MARK: - Pass Identity Summary Hero Card

struct PassBackHeroCard: View {
    let brandId: String
    let brandTitle: String
    let fields: [String: String]
    let palette: PassPalette

    private var titleText: String {
        switch brandId {
        case "airbnb": return fields["property"] ?? "The Glasshouse Loft, Soho"
        case "bookmyshow", "district": return fields["event"] ?? "Dune: Part Two (IMAX 70mm)"
        case "irctc": return fields["train"] ?? "12640 • Brindavan Superfast"
        case "indigo": return fields["flight"] ?? "IndiGo 6E 204"
        case "uber", "ola": return fields["vehicle"] ?? "Uber Black"
        case "zoomcar": return fields["vehicle"] ?? "Zoomcar Keyless Drive"
        case "zomato-dineout", "swiggy-dineout", "easydiner": return fields["restaurant"] ?? brandTitle
        default: return fields["event"] ?? fields["property"] ?? fields["vehicle"] ?? brandTitle
        }
    }

    private var subtitleText: String {
        switch brandId {
        case "airbnb":
            return "Access Pass Room \(fields["door_pin"] ?? "#402")"
        case "bookmyshow", "district":
            return "\(fields["venue"] ?? "PVR INOX Ambience Mall") • \(fields["format"] ?? "IMAX 70mm")"
        case "irctc":
            return "\(fields["origin"] ?? "SBC") → \(fields["destination"] ?? "MAS") • \(fields["class"] ?? "AC Chair Car")"
        case "indigo":
            return "\(fields["origin"] ?? "BLR") → \(fields["destination"] ?? "DEL") • Regular Fare"
        case "uber", "ola":
            return "\(fields["pickup"] ?? "Indiranagar") → \(fields["destination"] ?? "Kempegowda Airport")"
        default:
            return fields["booking_id"] ?? "Slip Verified Digital Pass"
        }
    }

    private var statusText: String {
        switch brandId {
        case "airbnb": return "ACTIVE KEY LINKED"
        case "bookmyshow", "district": return "ACTIVE & CONFIRMED"
        case "irctc": return fields["pnr_status"] ?? "CONFIRMED • RAC 0"
        case "indigo": return fields["status"] ?? "ACTIVE & SYNCED"
        case "uber", "ola": return "TRIP ACTIVE • ON ROUTE"
        case "zoomcar": return "CAR UNLOCKED • KEYLESS"
        case "zomato-dineout", "swiggy-dineout", "easydiner": return "RESERVED & CONFIRMED"
        case "cult", "golds-gym": return "ACTIVE MEMBERSHIP"
        default: return "ACTIVE & SYNCED"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Status bar & Issuer chip
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.emeraldGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.emeraldGreen.opacity(0.8), radius: 4)
                    Text(statusText.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.emeraldGreen)
                        .tracking(0.6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.emeraldGreen.opacity(0.12)).overlay(Capsule().strokeBorder(Color.emeraldGreen.opacity(0.25), lineWidth: 1)))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: iconForBrand)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.accentSoft)
                    Text(brandTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.06)).overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)))
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(SlipTheme.headline(size: 20, weight: .bold))
                    .foregroundStyle(SlipTheme.ink)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(SlipTheme.body(size: 13, weight: .regular))
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }

            SoftDivider(tint: Color.white.opacity(0.08))

            // 3-Metric Bento Grid
            HStack(spacing: 8) {
                metricColumn(label: metric1.0, value: metric1.1)
                metricColumn(label: metric2.0, value: metric2.1)
                metricColumn(label: metric3.0, value: metric3.1)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.15),
                            Color(red: 0.10, green: 0.10, blue: 0.12),
                            Color(red: 0.08, green: 0.08, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [palette.accent.opacity(0.35), SlipTheme.glassBorder], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                .shadow(color: palette.accent.opacity(0.15), radius: 16, y: 6)
        )
    }

    private func metricColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(SlipTheme.muted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metric1: (String, String) {
        switch brandId {
        case "airbnb": return ("PNR / BOOKING", fields["booking_id"] ?? "AB-40291")
        case "bookmyshow", "district": return ("AUDI", fields["screen"] ?? "02")
        case "irctc": return ("COACH / BERTH", "\(fields["coach"] ?? "C2") • \(fields["seat"] ?? "44")")
        case "indigo": return ("PNR / BOOKING", fields["pnr"] ?? "K9WQ8P")
        case "uber", "ola": return ("ETA", fields["eta"] ?? "28 MINS")
        case "zoomcar": return ("RANGE", "\(fields["range_km"] ?? "420") KM")
        case "zomato-dineout", "swiggy-dineout", "easydiner": return ("PARTY SIZE", "\(fields["party_size"] ?? "2") Guests")
        case "cult", "golds-gym": return ("TIER", fields["plan"] ?? "Elite Pass")
        default: return ("BOOKING ID", fields["booking_id"] ?? "PK-9821")
        }
    }

    private var metric2: (String, String) {
        switch brandId {
        case "airbnb": return ("ROOM / PIN", fields["door_pin"] ?? "#402")
        case "bookmyshow", "district": return ("SEATS", fields["seat"] ?? "F14, F15")
        case "irctc": return ("PNR NUMBER", fields["pnr"] ?? "284-9182740")
        case "indigo": return ("SEAT", fields["seat"] ?? "04F")
        case "uber", "ola": return ("DISTANCE", "34.8 KM")
        case "zoomcar": return ("PLATE", fields["plate"] ?? "KA 03 NB 4210")
        case "zomato-dineout", "swiggy-dineout", "easydiner": return ("TABLE", fields["table"] ?? "Table 14")
        case "cult", "golds-gym": return ("VALID THRU", fields["valid_thru"] ?? "Dec 2026")
        default: return ("SEAT / REF", fields["seat"] ?? fields["pnr"] ?? "CONFIRMED")
        }
    }

    private var metric3: (String, String) {
        switch brandId {
        case "airbnb": return ("DURATION", "5 Nights")
        case "bookmyshow", "district": return ("SHOWTIME", fields["time"] ?? "19:15")
        case "irctc": return ("CLASS", fields["class"] ?? "3A (GN)")
        case "indigo": return ("ZONE", fields["boarding_zone"] ?? "ZONE 1")
        case "uber", "ola": return ("START PIN", fields["ride_pin"] ?? "7294")
        case "zoomcar": return ("DOOR PIN", fields["door_pin"] ?? "9182")
        case "zomato-dineout", "swiggy-dineout", "easydiner": return ("SLOT", fields["time"] ?? "20:30")
        case "cult", "golds-gym": return ("CENTER", fields["center"] ?? "Indiranagar")
        default: return ("DATE", fields["date"] ?? fields["time"] ?? "TODAY")
        }
    }

    private var iconForBrand: String {
        switch brandId {
        case "airbnb": return "house.fill"
        case "bookmyshow", "district": return "film.fill"
        case "irctc", "uts": return "train.side.front.car"
        case "indigo": return "airplane"
        case "uber", "ola": return "car.fill"
        case "zoomcar": return "key.fill"
        case "zomato-dineout", "swiggy-dineout", "easydiner": return "fork.knife"
        case "cult", "golds-gym": return "figure.run"
        case "namma-metro", "chalo", "redbus": return "tram.fill"
        default: return "ticket.fill"
        }
    }
}

// MARK: - Airbnb Back Content (pass_details_airbnb_key_flip_info_sheet)

struct AirbnbBackContent: View {
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Stay Itinerary
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("STAY ITINERARY")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        Text("5 Nights Confirmed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(palette.accentSoft)
                    }

                    HStack(spacing: 10) {
                        itineraryTile(icon: "arrow.down.right", title: "Check-In", date: fields["check_in"] ?? "15 Oct", time: fields["check_in_time"] ?? "03:00 PM EST")
                        itineraryTile(icon: "arrow.up.right", title: "Check-Out", date: fields["check_out"] ?? "20 Oct", time: fields["check_out_time"] ?? "11:00 AM EST")
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.accentSoft)
                        Text(fields["property_type"] ?? "Master Suite & Penthouse Deck • Level 4 Elevator Entry")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SlipTheme.ink.opacity(0.8))
                    }
                }
            }

            // Access & Lock Protocol
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ACCESS & PROTOCOL")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        Text("NFC Apple VAS 2.0")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.accentSoft)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "wave.3.forward.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(palette.accentSoft)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keyless Contactless Tap")
                                .font(SlipTheme.headline(size: 14, weight: .semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Hold iPhone or Apple Watch near \(fields["lock_brand"] ?? "Schlage") door sensor. Works even when battery is reserved.")
                                .font(.system(size: 11))
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }

                    HStack(spacing: 8) {
                        copyCredentialTile(
                            label: "KEYPAD PIN",
                            value: fields["door_pin"] ?? "7392#",
                            sub: "Backup lock code",
                            onTap: { onCopy(fields["door_pin"] ?? "7392#", "Keypad PIN") }
                        )
                        copyCredentialTile(
                            label: "WI-FI PASS",
                            value: fields["wifi_password"] ?? "loftsoho2024",
                            sub: "SSID: \(fields["wifi_ssid"] ?? "Glasshouse_Guest_5G")",
                            onTap: { onCopy(fields["wifi_password"] ?? "loftsoho2024", "Wi-Fi Password") }
                        )
                    }
                }
            }

            // Host & Concierge
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("HOST & CONCIERGE")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.amber)
                            Text("4.98")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SlipTheme.ink)
                        }
                    }

                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 42, height: 42)
                            .overlay(Image(systemName: "person.2.fill").foregroundStyle(palette.accentSoft))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(fields["host"] ?? "Alexander & Sarah")
                                    .font(SlipTheme.headline(size: 14, weight: .semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(palette.accentSoft)
                            }
                            Text(fields["host_badge"] ?? "Superhosts • 6 years hosting")
                                .font(.system(size: 11))
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        let phone = fields["host_phone"] ?? "+12125550199"
                        if let url = URL(string: "tel:\(phone)") {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(SlipTheme.ink)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                        }
                    }

                    SoftDivider(tint: Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("STAY GUIDELINES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                        Text("• Quiet hours observed strictly from 10:00 PM – 8:00 AM.")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.ink.opacity(0.75))
                        Text("• No smoking or unauthorized events inside loft.")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.ink.opacity(0.75))
                    }
                }
            }
        }
    }

    private func itineraryTile(icon: String, title: String, date: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(SlipTheme.muted)

            Text(date)
                .font(SlipTheme.headline(size: 16, weight: .bold))
                .foregroundStyle(SlipTheme.ink)
            Text(time)
                .font(.system(size: 11))
                .foregroundStyle(SlipTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.04)))
    }

    private func copyCredentialTile(label: String, value: String, sub: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(label)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(palette.accentSoft)
                }
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accentSoft)
                    .lineLimit(1)
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - BookMyShow Back Content (pass_details_bookmyshow_flip_info_sheet)

struct BookMyShowBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Venue & Entry Logistics
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.accentSoft)
                        Text("VENUE & ENTRY LOGISTICS")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Address & Valet")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                        Text(fields["venue"] ?? "Ambience Mall, Nelson Mandela Marg, Vasant Kunj, New Delhi")
                            .font(SlipTheme.body(size: 13, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Dedicated Director's Cut valet at Gate 2 with express lounge elevator.")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.muted)
                    }

                    SoftDivider(tint: Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Technical Projection & Sound")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                        Text("IMAX with Laser 70mm Aspect Ratio 1.43:1 dual-rig, Dolby Atmos 128 Channels.")
                            .font(.system(size: 12))
                            .foregroundStyle(SlipTheme.ink.opacity(0.85))
                    }
                }
            }

            // F&B Butler Voucher
            PassBackCardContainer {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("F&B Butler Voucher")
                                .font(SlipTheme.headline(size: 14, weight: .semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Spacer()
                            Text("PRE-ORDERED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.amber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.amber.opacity(0.15)))
                        }
                        Text(fields["fnb"] ?? "2x Prime Recliner + Gourmet Popcorn Combo & 2x Cold Brew. Present QR at Butler or tap in-seat call.")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
            }

            // Transaction & Terms
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TRANSACTION & TERMS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)

                    infoRow(label: "Booking Reference", value: fields["booking_id"] ?? "BMS-WMS9842109") {
                        onCopy(fields["booking_id"] ?? "BMS-WMS9842109", "Booking Reference")
                    }
                    infoRow(label: "Payment Method", value: "Apple Pay (UPI Linked)", onCopy: nil)
                    infoRow(label: "Purchased Date", value: fields["date"] ?? "20 Oct 2024 • 14:22 IST", onCopy: nil)

                    SoftDivider(tint: Color.white.opacity(0.06))

                    Text("Cancellation Policy")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(SlipTheme.muted)
                    Text("Non-refundable within 4 hours of showtime. Exchange to voucher permitted up to 2 hours prior via BookMyShow Concierge.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
        }
    }

    private func infoRow(label: String, value: String, onCopy: (() -> Void)?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(SlipTheme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(SlipTheme.ink)
            if let onCopy {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(palette.accentSoft)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Uber / Ola Mobility Back Content (pass_details_uber_ride_flip_info_sheet)

struct MobilityBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Chauffeur & Vehicle Profile
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "person.crop.circle.fill").font(.system(size: 32)).foregroundStyle(SlipTheme.ink))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fields["driver"] ?? "Vikram S.")
                                .font(SlipTheme.headline(size: 15, weight: .semibold))
                                .foregroundStyle(SlipTheme.ink)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.amber)
                                Text("4.96 • 6,240+ trips")
                                    .font(.system(size: 11))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Button {} label: {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SlipTheme.ink)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color.white.opacity(0.08)))
                            }
                            Button {} label: {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SlipTheme.ink)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color.white.opacity(0.08)))
                            }
                        }
                    }

                    SoftDivider(tint: Color.white.opacity(0.06))

                    // Vehicle & Plate
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fields["vehicle"] ?? "Mercedes-Benz E-Class")
                                .font(SlipTheme.headline(size: 13, weight: .semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Black Obsidian Metallic")
                                .font(.system(size: 11))
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Text(fields["plate"] ?? "KA 01 MJ 7720")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlipTheme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.08)))
                    }
                }
            }

            // Start Ride PIN / Unlock Code
            PassBackCardContainer {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("START RIDE PIN")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Text("Provide this code to driver at vehicle")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()
                    let pin = fields["ride_pin"] ?? fields["door_pin"] ?? "7294"
                    Button {
                        onCopy(pin, "Ride PIN")
                    } label: {
                        HStack(spacing: 6) {
                            Text(pin)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundStyle(palette.accentSoft)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Apple VAS 2.0 Encrypted Cab Verification
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.accentSoft)
                        Text("APPLE VAS 2.0 CAB VERIFICATION")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Text("VAS token active. Hold your device near the dashboard mount cradle to automatically broadcast ride credentials and confirm manifest.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.ink.opacity(0.75))
                }
            }
        }
    }
}

// MARK: - IRCTC Back Content (pass_details_irctc_train_ticket)

struct IRCTCBackContent: View {
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Train & Station Journey Details
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "train.side.front.car")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.accentSoft)
                        Text("TRAIN & TRANSIT LOGISTICS")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        Text("ON TIME")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.emeraldGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.emeraldGreen.opacity(0.15)))
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DEPARTURE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(fields["dep"] ?? "16:55")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Platform \(fields["origin_platform"] ?? "3")")
                                .font(.system(size: 11))
                                .foregroundStyle(palette.accentSoft)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ARRIVAL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(fields["arr"] ?? "08:35")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Platform \(fields["dest_platform"] ?? "1")")
                                .font(.system(size: 11))
                                .foregroundStyle(palette.accentSoft)
                        }
                    }

                    SoftDivider(tint: Color.white.opacity(0.06))

                    // PNR & Passenger
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PNR NUMBER")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            let pnr = fields["pnr"] ?? "284-9182740"
                            Button {
                                onCopy(pnr, "PNR Number")
                            } label: {
                                HStack(spacing: 4) {
                                    Text(pnr)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(SlipTheme.ink)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 10))
                                        .foregroundStyle(palette.accentSoft)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("MEAL CHOICE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text("Veg Opted")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(SlipTheme.ink)
                        }
                    }
                }
            }

            // Rail Madad Helpline
            PassBackCardContainer {
                HStack(spacing: 12) {
                    Image(systemName: "headset")
                        .font(.system(size: 22))
                        .foregroundStyle(palette.accentSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("24/7 Rail Madad & IRCTC Concierge")
                            .font(SlipTheme.headline(size: 13, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Dial 139 for live security, berth assistance & grievance redressal.")
                            .font(.system(size: 11))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()
                    if let url = URL(string: "tel:139") {
                        Link(destination: url) {
                            Text("139")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Flight Back Content (pass_details_indigo_boarding_card)

struct FlightBackContent: View {
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEPARTURE TERMINAL & ADDRESS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text("\(fields["origin"] ?? "Kempegowda International Airport"), Terminal \(fields["terminal"] ?? fields["origin_terminal"] ?? "1")")
                        .font(SlipTheme.body(size: 13, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Gate \(fields["gate"] ?? "18B") (Subject to change prior to boarding)")
                        .font(.system(size: 11))
                        .foregroundStyle(palette.accentSoft)
                }
            }

            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("BAGGAGE ALLOWANCE")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text("15 kg Check-in (1 piece), 7 kg Cabin Handbag")
                        .font(SlipTheme.body(size: 13, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Excess luggage billed at ₹550/kg at kiosk counter.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.muted)
                }
            }

            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FARE RULES & CONDITIONS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text("Pass issued subject to Conditions of Carriage & DGCA civil aviation security requirements. Boarding gates close strictly 25 minutes prior to scheduled departure.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.ink.opacity(0.75))
                }
            }
        }
    }
}

// MARK: - Dining Back Content

struct DiningBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("RESERVATION & PERKS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fields["restaurant"] ?? "Farzi Cafe")
                                .font(SlipTheme.headline(size: 15, weight: .bold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("\(fields["party_size"] ?? "2") Guests • \(fields["time"] ?? "20:30")")
                                .font(.system(size: 12))
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Text("25% OFF BILL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.amber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.amber.opacity(0.15)))
                    }
                }
            }

            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LOCATION & VALET")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text(fields["address"] ?? fields["city"] ?? "UB City, Vittal Mallya Rd, Bengaluru")
                        .font(SlipTheme.body(size: 13, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Complimentary valet parking for Slip Pass holders.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
        }
    }
}

// MARK: - Transit Bus & Metro Back Content

struct TransitBusMetroBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TRANSIT PASS LOGISTICS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ROUTE LINE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(fields["line"] ?? fields["bus_operator"] ?? "Purple Line")
                                .font(SlipTheme.headline(size: 14, weight: .bold))
                                .foregroundStyle(SlipTheme.ink)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("FARE PAID")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(fields["fare"] ?? "₹45.00")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(palette.accentSoft)
                        }
                    }
                }
            }

            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NFC TAP GATE INSTRUCTIONS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text("Hold iPhone near the automatic gate reader at entry & exit. Valid for 90 minutes from tap-in.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.ink.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Fitness & Gym Back Content

struct FitnessBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MEMBERSHIP PRIVILEGES")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Text("All-Access Pass • Center: \(fields["center"] ?? "Indiranagar")")
                        .font(SlipTheme.body(size: 13, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Includes steam room, personal locker & towel service.")
                        .font(.system(size: 11))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
        }
    }
}

// MARK: - Retail Loyalty Back Content

struct RetailLoyaltyBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("REWARDS & REBATES")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AVAILABLE BALANCE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text("\(fields["points"] ?? "1,450") Coins")
                                .font(SlipTheme.headline(size: 16, weight: .bold))
                                .foregroundStyle(palette.accentSoft)
                        }
                        Spacer()
                        Text("₹1 = 1 Coin")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
            }
        }
    }
}

// MARK: - Generic Back Content

struct GenericBackContent: View {
    let brandId: String
    let fields: [String: String]
    let palette: PassPalette
    let onCopy: (String, String) -> Void

    var body: some View {
        let backRows = PassBackContent.rows(brandId: brandId, fields: fields)
        if !backRows.isEmpty {
            PassBackCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ADDITIONAL DETAILS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)

                    ForEach(backRows) { row in
                        HStack {
                            Text(row.label.uppercased())
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Spacer()
                            Text(row.value)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SlipTheme.ink)
                            Button {
                                onCopy(row.value, row.label)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundStyle(palette.accentSoft)
                            }
                            .buttonStyle(.plain)
                        }
                        SoftDivider(tint: Color.white.opacity(0.05))
                    }
                }
            }
        }
    }
}

// MARK: - Shared Glass Card Container

struct PassBackCardContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
            )
    }
}

// MARK: - PassBackToggleRow

struct PassBackToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SlipTheme.body(size: 14, weight: .semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(2)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.emeraldGreen))
        .padding(14)
    }
}

private extension Color {
    static let emeraldGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let amber = Color(red: 0.95, green: 0.65, blue: 0.15)
}

private extension SlipTheme {
    static func headline(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
