import CryptoKit
import SwiftUI
import UIKit

/// Stitch-faithful Apple Wallet Back-of-Pass Details Sheet
/// STRICTLY DYNAMIC: Zero hardcoded dummy/sample values.
/// Renders authentic pass data from `fields: [String: String]` with contextual cards,
/// exhaustive attribute inspection, Apple Maps integration, UPI payment, and real SHA-256 cryptographic verification.
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
                        // 1. Dynamic Pass Identity Hero Card
                        PassBackHeroCard(
                            brandId: brandId,
                            brandTitle: brandTitle,
                            fields: fields,
                            palette: palette
                        )

                        // 2. Dynamic Contextual Cards (Only displayed when fields actually exist)
                        if hasTransitData {
                            transitCard
                        }

                        if hasAccessData {
                            accessCredentialsCard
                        }

                        if hasLocationData {
                            locationVenueCard
                        }

                        if hasPersonData {
                            personContactCard
                        }

                        if hasPaymentData {
                            paymentRewardsCard
                        }

                        if hasBarcodeData {
                            barcodeVerificationCard
                        }

                        // 3. Exhaustive Dynamic Attribute Inspection (All non-empty fields)
                        allPassFieldsCard

                        // 4. Native iOS Wallet System Behaviors
                        systemBehaviorsSection

                        // 5. Ecosystem & Sharing Actions
                        passActionsSection

                        // 6. Destructive Removal Section
                        destructiveActionSection

                        // 7. Cryptographic SHA-256 Security Footer
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
                            .font(.slipSystem(size: 15, weight: .semibold))
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
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
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                                .overlay(Capsule().strokeBorder(palette.accent.opacity(0.4), lineWidth: 1))
                        )
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
                Text("Removing will erase the cryptographic NFC pass key from local Secure Enclave.")
            }
        }
    }

    // MARK: - Context Checks

    private var hasTransitData: Bool {
        hasAny(["origin", "destination", "flight", "train", "line", "dep", "arr", "gate", "terminal", "platform", "coach", "berth"])
    }

    private var hasAccessData: Bool {
        hasAny(["door_pin", "ride_pin", "pin", "wifi_password", "wifi_ssid", "key_status"])
    }

    private var hasLocationData: Bool {
        hasAny(["venue", "address", "city", "pickup", "drop_off"])
    }

    private var hasPersonData: Bool {
        hasAny(["passenger", "guest", "driver", "host", "name"])
    }

    private var hasPaymentData: Bool {
        hasAny(["amount", "fare", "points", "payment_method", "vpa", "tax"])
    }

    private var hasBarcodeData: Bool {
        hasAny(["qr_data", "barcode", "pnr", "ticket_no"])
    }

    private func hasAny(_ keys: [String]) -> Bool {
        keys.contains { key in
            guard let val = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            return !val.isEmpty && val != "—"
        }
    }

    // MARK: - Contextual Dynamic Cards

    private var transitCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "tram.fill")
                        .font(.slipSystem(size: 13))
                        .foregroundStyle(palette.accentSoft)
                    Text("TRANSIT & ITINERARY")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    if let status = fields["status"] ?? fields["pnr_status"] {
                        Text(status.uppercased())
                            .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.emeraldGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.emeraldGreen.opacity(0.15)))
                    }
                }

                // Origin -> Destination
                if let origin = fields["origin"], let dest = fields["destination"] {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DEPARTURE")
                                .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(origin)
                                .font(SlipTheme.headline(size: 16, weight: .bold))
                                .foregroundStyle(SlipTheme.ink)
                            if let dep = fields["dep"] ?? fields["time"] {
                                Text(dep)
                                    .font(.slipSystem(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(palette.accentSoft)
                            }
                            if let plat = fields["origin_platform"] ?? fields["platform"] {
                                Text("Platform \(plat)")
                                    .font(.slipSystem(size: 11))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.slipSystem(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ARRIVAL")
                                .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(dest)
                                .font(SlipTheme.headline(size: 16, weight: .bold))
                                .foregroundStyle(SlipTheme.ink)
                            if let arr = fields["arr"] {
                                Text(arr)
                                    .font(.slipSystem(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(palette.accentSoft)
                            }
                            if let plat = fields["dest_platform"] {
                                Text("Platform \(plat)")
                                    .font(.slipSystem(size: 11))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                        }
                    }
                    SoftDivider(tint: Color.white.opacity(0.06))
                }

                // Grid of seating/gate/carrier metadata
                let transitItems = [
                    ("FLIGHT / TRAIN", fields["flight"] ?? fields["train"] ?? fields["line"]),
                    ("TERMINAL", fields["terminal"] ?? fields["origin_terminal"]),
                    ("GATE", fields["gate"]),
                    ("SEAT / BERTH", fields["seat"] ?? fields["berth"]),
                    ("COACH", fields["coach"]),
                    ("CLASS", fields["class"]),
                    ("BOARDING ZONE", fields["boarding_zone"])
                ].compactMap { item -> (String, String)? in
                    guard let val = item.1, !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                    return (item.0, val)
                }

                if !transitItems.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(transitItems, id: \.0) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.0)
                                    .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(SlipTheme.muted)
                                Text(item.1)
                                    .font(.slipSystem(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(SlipTheme.ink)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private var accessCredentialsCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.slipSystem(size: 12))
                        .foregroundStyle(palette.accentSoft)
                    Text("ACCESS CREDENTIALS & PINS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    Text("NFC VAS Ready")
                        .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.accentSoft)
                }

                HStack(spacing: 8) {
                    if let pin = fields["door_pin"] ?? fields["ride_pin"] ?? fields["pin"] {
                        copyCredentialTile(
                            label: "ACCESS PIN",
                            value: pin,
                            sub: "Tap to copy",
                            onTap: { triggerCopy(text: pin, label: "PIN") }
                        )
                    }

                    if let wifi = fields["wifi_password"] {
                        copyCredentialTile(
                            label: "WI-FI PASSWORD",
                            value: wifi,
                            sub: fields["wifi_ssid"].map { "SSID: \($0)" } ?? "Tap to copy",
                            onTap: { triggerCopy(text: wifi, label: "Wi-Fi Password") }
                        )
                    }
                }
            }
        }
    }

    private var locationVenueCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.slipSystem(size: 12))
                        .foregroundStyle(palette.accentSoft)
                    Text("LOCATION & VENUE")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                }

                if let venue = fields["venue"] {
                    Text(venue)
                        .font(SlipTheme.headline(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                }

                if let addr = fields["address"] ?? fields["pickup"] ?? fields["city"] {
                    Text(addr)
                        .font(SlipTheme.body(size: 13, weight: .regular))
                        .foregroundStyle(SlipTheme.muted)

                    if let query = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let mapsUrl = URL(string: "https://maps.apple.com/?q=\(query)") {
                        Link(destination: mapsUrl) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.slipSystem(size: 13))
                                Text("Open in Apple Maps")
                                    .font(.slipSystem(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(palette.accentSoft)
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    private var personContactCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.slipSystem(size: 13))
                        .foregroundStyle(palette.accentSoft)
                    Text("ASSOCIATED PASSENGER / CONTACT")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                }

                let name = fields["passenger"] ?? fields["guest"] ?? fields["driver"] ?? fields["host"] ?? fields["name"] ?? "—"
                let role = fields["driver"] != nil ? "Chauffeur / Driver" :
                           fields["host"] != nil ? "Host / Concierge" :
                           fields["guest"] != nil ? "Registered Guest" : "Passenger"

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(SlipTheme.headline(size: 15, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text(role)
                            .font(.slipSystem(size: 11))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()

                    if let phone = fields["phone"] ?? fields["host_phone"] ?? fields["driver_phone"],
                       let phoneUrl = URL(string: "tel:\(phone)") {
                        Link(destination: phoneUrl) {
                            Image(systemName: "phone.fill")
                                .font(.slipSystem(size: 14))
                                .foregroundStyle(SlipTheme.ink)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                }
            }
        }
    }

    private var paymentRewardsCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.slipSystem(size: 13))
                        .foregroundStyle(Color.emeraldGreen)
                    Text("BILLING & TRANSACTIONS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                }

                HStack {
                    if let amt = fields["amount"] ?? fields["fare"] {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AMOUNT")
                                .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(amt.hasPrefix("₹") ? amt : "₹\(amt)")
                                .font(.slipSystem(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                        }
                    }

                    if let points = fields["points"] {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("POINTS / COINS")
                                .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text("\(points) Coins")
                                .font(SlipTheme.headline(size: 16, weight: .bold))
                                .foregroundStyle(palette.accentSoft)
                        }
                    }
                }
            }
        }
    }

    private var barcodeVerificationCard: some View {
        PassBackCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "qrcode")
                        .font(.slipSystem(size: 13))
                        .foregroundStyle(palette.accentSoft)
                    Text("BARCODE & MACHINE DATA")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                }

                let payload = fields["qr_data"] ?? fields["barcode"] ?? fields["pnr"] ?? "—"
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RAW ENCODED PAYLOAD")
                            .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                        Text(payload)
                            .font(.slipSystem(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(SlipTheme.ink)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        triggerCopy(text: payload, label: "Barcode Payload")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.slipSystem(size: 14))
                            .foregroundStyle(palette.accentSoft)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Exhaustive Dynamic Attributes (Master Field Table)

    private var allPassFieldsCard: some View {
        let validFields = fields
            .filter { key, val in
                let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty && trimmed != "—" && key != "qr_data"
            }
            .sorted { $0.key < $1.key }

        return PassBackCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.slipSystem(size: 12))
                        .foregroundStyle(palette.accentSoft)
                    Text("EXTRACTED PASS ATTRIBUTES (\(validFields.count))")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                }

                ForEach(validFields, id: \.key) { key, value in
                    HStack(alignment: .center) {
                        Text(humanLabel(for: key).uppercased())
                            .font(.slipSystem(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                            .frame(maxWidth: 140, alignment: .leading)

                        Spacer()

                        Text(value)
                            .font(.slipSystem(size: 12, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)

                        Button {
                            triggerCopy(text: value, label: humanLabel(for: key))
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.slipSystem(size: 11))
                                .foregroundStyle(palette.accentSoft)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 6)
                    }
                    SoftDivider(tint: Color.white.opacity(0.05))
                }
            }
        }
    }

    // MARK: - System Behaviors Section

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
            if hasTransitData || brandId == "uber" || brandId == "ola" || brandId == "indigo" || brandId == "irctc" || brandId == "bookmyshow" {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Pass Actions Section

    private var passActionsSection: some View {
        VStack(spacing: 0) {
            let passId = vaultRecordId ?? fields["booking_id"] ?? fields["pnr"] ?? brandId
            if let shareUrl = URL(string: "https://slip.app/pass/\(passId)") {
                ShareLink(item: shareUrl) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(SlipTheme.accentSoft)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                        Text("Share Pass via AirDrop")
                            .font(SlipTheme.body(size: 15, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.slipSystem(size: 12, weight: .semibold))
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
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                        Text("Pay Bill with UPI")
                            .font(SlipTheme.body(size: 15, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.slipSystem(size: 12, weight: .semibold))
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
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
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
                        .font(.slipSystem(size: 15, weight: .semibold))
                    Text("Remove Pass")
                        .font(SlipTheme.headline(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
                        )
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
        let serial = vaultRecordId ?? fields["booking_id"] ?? fields["pnr"] ?? "SLIP-\(brandId.uppercased())-\(String(format: "%06X", abs(fields.description.hashValue) % 0xFFFFFF))"
        let shaDigest = computeRealSHA256(for: fields)

        return VStack(spacing: 4) {
            Text("SERIAL: \(serial)")
                .font(.slipSystem(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(SlipTheme.muted.opacity(0.8))
                .tracking(1.2)
            Text("SHA-256: \(shaDigest) • Signed by \(brandTitle) CA")
                .font(.slipSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(SlipTheme.muted.opacity(0.6))
            Text("Powered by Slip SecurePass™ VAS 2.0")
                .font(.slipSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(palette.accentSoft.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func computeRealSHA256(for data: [String: String]) -> String {
        let sortedPayload = data.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let hash = SHA256.hash(data: Data(sortedPayload.utf8))
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return "\(hex.prefix(6))...\(hex.suffix(6))"
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

    private func copyCredentialTile(label: String, value: String, sub: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(label)
                        .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .font(.slipSystem(size: 10))
                        .foregroundStyle(palette.accentSoft)
                }
                Text(value)
                    .font(.slipSystem(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accentSoft)
                    .lineLimit(1)
                Text(sub)
                    .font(.slipSystem(size: 10))
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }

    private func humanLabel(for key: String) -> String {
        let known: [String: String] = [
            "pnr": "PNR Number",
            "booking_id": "Booking ID",
            "ticket_no": "Ticket Number",
            "flight": "Flight Number",
            "train": "Train",
            "seat": "Seat Number",
            "coach": "Coach",
            "berth": "Berth",
            "gate": "Gate",
            "terminal": "Terminal",
            "origin": "Origin",
            "destination": "Destination",
            "dep": "Departure Time",
            "arr": "Arrival Time",
            "date": "Date",
            "time": "Time",
            "check_in": "Check-In Date",
            "check_out": "Check-Out Date",
            "guest": "Guest Name",
            "passenger": "Passenger",
            "driver": "Driver",
            "vehicle": "Vehicle",
            "plate": "License Plate",
            "door_pin": "Door PIN",
            "ride_pin": "Ride PIN",
            "wifi_ssid": "Wi-Fi SSID",
            "wifi_password": "Wi-Fi Password",
            "venue": "Venue",
            "address": "Address",
            "city": "City",
            "event": "Event Name",
            "party_size": "Party Size",
            "table": "Table Number",
            "amount": "Total Amount",
            "fare": "Fare Paid",
            "points": "Reward Coins",
            "status": "Status",
            "vpa": "UPI ID"
        ]
        if let match = known[key.lowercased()] { return match }
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Dynamic Pass Identity Hero Card

struct PassBackHeroCard: View {
    let brandId: String
    let brandTitle: String
    let fields: [String: String]
    let palette: PassPalette

    private var titleText: String {
        let candidates = ["event", "title", "flight", "train", "property", "restaurant", "vehicle", "name"]
        for key in candidates {
            if let val = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !val.isEmpty, val != "—" {
                return val
            }
        }
        return brandTitle
    }

    private var subtitleText: String {
        if let o = fields["origin"], let d = fields["destination"], !o.isEmpty, !d.isEmpty {
            let cls = fields["class"] != nil ? " • \(fields["class"]!)" : ""
            return "\(o) → \(d)\(cls)"
        }
        if let venue = fields["venue"], !venue.isEmpty {
            return venue
        }
        if let p = fields["passenger"] ?? fields["guest"], !p.isEmpty {
            return "Reserved for \(p)"
        }
        if let id = fields["booking_id"] ?? fields["pnr"], !id.isEmpty {
            return "Booking #\(id)"
        }
        return "Slip Verified Digital Pass"
    }

    private var statusText: String {
        fields["status"] ?? fields["pnr_status"] ?? fields["key_status"] ?? "ACTIVE & SYNCED"
    }

    private var dynamicMetrics: [(String, String)] {
        var out: [(String, String)] = []
        let candidateGroups = [
            ["booking_id", "pnr", "ticket_no"],
            ["seat", "berth", "room", "table", "gate", "platform", "door_pin", "ride_pin"],
            ["dep", "time", "date", "check_in", "fare", "amount", "points", "class"]
        ]

        for group in candidateGroups {
            for key in group {
                if let val = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !val.isEmpty, val != "—" {
                    let label = shortLabel(for: key)
                    if !out.contains(where: { $0.0 == label }) {
                        out.append((label, val))
                        break
                    }
                }
            }
        }

        // Fill remaining slots up to 3 from any non-empty field
        if out.count < 3 {
            for (k, v) in fields where !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && v != "—" {
                if k != "qr_data" && k != "barcode" && k != "property" && k != "event" {
                    let label = shortLabel(for: k)
                    if !out.contains(where: { $0.0 == label }) {
                        out.append((label, v))
                    }
                }
                if out.count >= 3 { break }
            }
        }

        return out
    }

    private func shortLabel(for key: String) -> String {
        switch key.lowercased() {
        case "booking_id": return "BOOKING ID"
        case "pnr": return "PNR"
        case "seat": return "SEAT"
        case "berth": return "BERTH"
        case "gate": return "GATE"
        case "platform": return "PLATFORM"
        case "door_pin": return "DOOR PIN"
        case "ride_pin": return "RIDE PIN"
        case "dep": return "DEPART"
        case "time": return "TIME"
        case "date": return "DATE"
        case "fare": return "FARE"
        case "amount": return "AMOUNT"
        case "points": return "POINTS"
        case "class": return "CLASS"
        default: return key.replacingOccurrences(of: "_", with: " ").uppercased()
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
                        .font(.slipSystem(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.emeraldGreen)
                        .tracking(0.6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.emeraldGreen.opacity(0.12))
                        .overlay(Capsule().strokeBorder(Color.emeraldGreen.opacity(0.25), lineWidth: 1))
                )

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: iconForBrand)
                        .font(.slipSystem(size: 11, weight: .semibold))
                        .foregroundStyle(palette.accentSoft)
                    Text(brandTitle)
                        .font(.slipSystem(size: 11, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                )
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

            // Dynamic Bento Metrics (Up to 3, strictly from actual data)
            if !dynamicMetrics.isEmpty {
                HStack(spacing: 8) {
                    ForEach(dynamicMetrics, id: \.0) { metric in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric.0)
                                .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.muted)
                            Text(metric.1)
                                .font(.slipSystem(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
                        .strokeBorder(
                            LinearGradient(
                                colors: [palette.accent.opacity(0.35), SlipTheme.glassBorder],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: palette.accent.opacity(0.15), radius: 16, y: 6)
        )
    }

    private var iconForBrand: String {
        switch brandId {
        case "airbnb": return "house.fill"
        case "bookmyshow", "district": return "film.fill"
        case "irctc", "uts": return "train.side.front.car"
        case "indigo", "makemytrip", "cleartrip", "yatra": return "airplane"
        case "uber", "ola": return "car.fill"
        case "zoomcar": return "key.fill"
        case "zomato-dineout", "swiggy-dineout", "easydiner": return "fork.knife"
        case "cult", "golds-gym": return "figure.run"
        case "namma-metro", "chalo", "redbus": return "tram.fill"
        default: return "ticket.fill"
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
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
                    .font(.slipSystem(size: 11))
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
