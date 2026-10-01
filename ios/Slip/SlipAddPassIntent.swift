import AppIntents
import Foundation

/// Zero-OCR path: Siri / Shortcuts hand structured booking fields into Slip.
struct SlipAddPassIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Pass to Slip"
    static var description = IntentDescription(
        "Add a ticket using structured fields from Mail, Messages, or Shortcuts — no screenshot OCR required."
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Brand", description: "e.g. bookmyshow, indigo, irctc, swiggy-dineout")
    var brand: String

    @Parameter(title: "Booking ID")
    var bookingId: String?

    @Parameter(title: "PNR")
    var pnr: String?

    @Parameter(title: "QR or barcode payload")
    var qrPayload: String?

    @Parameter(title: "Event or movie")
    var event: String?

    @Parameter(title: "Restaurant or property")
    var placeName: String?

    @Parameter(title: "Origin")
    var origin: String?

    @Parameter(title: "Destination")
    var destination: String?

    @Parameter(title: "Seat")
    var seat: String?

    @Parameter(title: "Date or showtime text")
    var whenText: String?

    @Parameter(title: "Passenger or guest name")
    var passenger: String?

    @Parameter(title: "Extra notes")
    var notes: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let templateId = HybridPassFill.normalizeBrand(brand)
        guard !templateId.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: "Unknown brand. Try bookmyshow, indigo, irctc, or upi."))
        }

        var fields: [String: String] = [:]
        func put(_ key: String, _ value: String?) {
            let v = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty { fields[key] = v }
        }

        put("booking_id", bookingId)
        put("pnr", pnr)
        put("qr_data", qrPayload)
        put("event", event)
        put("origin", origin)
        put("destination", destination)
        put("seat", seat)
        put("time", whenText)
        put("date", whenText)
        put("passenger", passenger)
        put("guest", passenger)
        put("note", notes)

        if let place = placeName?.trimmingCharacters(in: .whitespacesAndNewlines), !place.isEmpty {
            switch templateId {
            case "airbnb": fields["property"] = place
            case "easydiner", "zomato-dineout", "swiggy-dineout": fields["restaurant"] = place
            case "bookmyshow", "district": fields["venue"] = place
            default:
                if fields["restaurant"] == nil { fields["restaurant"] = place }
                if fields["venue"] == nil { fields["venue"] = place }
            }
        }

        // Deterministic: QR never invented; prefer explicit payload.
        let qr = (qrPayload ?? fields["qr_data"] ?? fields["pnr"] ?? fields["booking_id"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !qr.isEmpty { fields["qr_data"] = qr }

        let ticket = ExtractedTicket(
            qrPayload: qr.isEmpty ? nil : qr,
            barcodeSymbology: qr.isEmpty ? nil : "qr",
            recognizedText: notes ?? [event, placeName, origin, destination].compactMap { $0 }.joined(separator: "\n"),
            tokens: [],
            createdAt: Date()
        )

        var result = ClassificationResult(
            templateId: templateId,
            displayName: BrandPassRegistry.friendlyName(for: templateId),
            confidence: 0.96,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Structured handoff via App Intent / Siri (zero-OCR)",
            needsManualBrandPick: false,
            extracted: ticket,
            createdAt: Date()
        )
        result = BrandPassRegistry.enrich(result)
        SharedInbox.save(result)

        return .result(
            dialog: IntentDialog(stringLiteral: "\(result.displayName) is ready in Slip — open the app to confirm and add to Wallet.")
        )
    }
}
