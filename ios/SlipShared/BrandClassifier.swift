import Foundation

enum BrandClassifier {
    /// Maps on-device extraction → template + fields. Pure local rules (IP layer).
    static func classify(_ ticket: ExtractedTicket) -> ClassificationResult {
        let hay = ticket.haystack
        let qr = ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let upi = classifyUPI(qr: qr, hay: hay, ticket: ticket) { return upi }
        if let cult = classifyCult(qr: qr, hay: hay, ticket: ticket) { return cult }
        if let metro = classifyNammaMetro(qr: qr, hay: hay, ticket: ticket) { return metro }
        if let bms = classifyBookMyShow(qr: qr, hay: hay, ticket: ticket) { return bms }
        if let irctc = classifyIRCTC(qr: qr, hay: hay, ticket: ticket) { return irctc }
        if let indigo = classifyIndigo(qr: qr, hay: hay, ticket: ticket) { return indigo }
        if let airline = classifyAirlineHint(qr: qr, hay: hay, ticket: ticket) { return airline }

        // Low confidence fallback — force Marketplace pick in UI
        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }
        return ClassificationResult(
            templateId: "",
            displayName: "Unknown",
            confidence: 0.15,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Could not match a brand from screenshot text. Pick one from the marketplace.",
            needsManualBrandPick: true,
            extracted: ticket,
            createdAt: Date()
        )
    }

    // MARK: - Brand rules

    private static func classifyUPI(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let isUPI = qr.lowercased().hasPrefix("upi://")
            || hay.contains("upi://pay")
            || (hay.contains("upi") && (hay.contains("scan") || hay.contains("pay")))
        guard isUPI else { return nil }

        var fields: [String: String] = [
            "qr_data": qr.isEmpty ? (ticket.qrPayload ?? "") : qr,
            "name": ""
        ]
        if let name = upiQueryValue(qr, key: "pn") ?? upiQueryValue(ticket.qrPayload ?? "", key: "pn") {
            fields["name"] = name.replacingOccurrences(of: "+", with: " ")
        } else if let named = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:name|payee)\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,})"#) {
            fields["name"] = named
        }

        return result(
            templateId: "upi",
            displayName: "UPI Get Paid",
            confidence: qr.lowercased().hasPrefix("upi://") ? 0.98 : 0.75,
            fields: fields,
            rationale: "Detected UPI payment QR",
            ticket: ticket
        )
    }

    private static func classifyCult(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("cult.fit")
            || hay.contains("cultfit")
            || hay.contains("cure.fit")
            || (hay.contains("cult") && (hay.contains("member") || hay.contains("check-in") || hay.contains("check in")))
        guard hit || (hay.contains("member") && hay.contains("fitness") && !qr.isEmpty) else { return nil }

        var fields: [String: String] = [
            "qr_data": qr,
            "name": "",
            "membership": "Member"
        ]
        if let name = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:member|name)\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,})"#) {
            fields["name"] = name
        }
        if let plan = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(elite|pro|play|pass|unlimited)"#) {
            fields["membership"] = plan.capitalized
        }

        return result(
            templateId: "cult",
            displayName: "Cult.fit",
            confidence: hay.contains("cult") ? 0.92 : 0.7,
            fields: fields,
            rationale: "Detected Cult.fit membership cues",
            ticket: ticket
        )
    }

    private static func classifyNammaMetro(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("namma metro")
            || hay.contains("bmrcl")
            || hay.contains("nammametro")
            || (hay.contains("metro") && (hay.contains("bengaluru") || hay.contains("bangalore") || hay.contains("purple") || hay.contains("green line")))
        guard hit else { return nil }

        let stations = knownNammaStations()
        let found = stations.filter { hay.contains($0.name.lowercased()) || hay.contains($0.id.lowercased()) }

        var origin = ""
        var destination = ""
        if found.count >= 2 {
            origin = found[0].name
            destination = found[1].name
        } else if let from = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:from|origin)\s*[:\-]?\s*([A-Za-z .]{3,})"#),
                  let to = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:to|destination)\s*[:\-]?\s*([A-Za-z .]{3,})"#) {
            origin = from.trimmingCharacters(in: .whitespaces)
            destination = to.trimmingCharacters(in: .whitespaces)
        } else if found.count == 1 {
            origin = found[0].name
        }

        let fields: [String: String] = [
            "qr_data": qr,
            "origin": origin,
            "destination": destination,
            "passenger": ""
        ]
        let stationIds = found.prefix(10).map(\.id)

        return result(
            templateId: "namma-metro",
            displayName: "Namma Metro",
            confidence: found.count >= 2 ? 0.9 : 0.72,
            fields: fields,
            stationIds: Array(stationIds),
            rationale: "Detected Namma Metro transit ticket",
            ticket: ticket
        )
    }

    private static func classifyBookMyShow(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("bookmyshow")
            || hay.contains("book my show")
            || hay.contains("bms")
            || hay.contains("paytm insider")
            || (hay.contains("seat") && (hay.contains("cinema") || hay.contains("theatre") || hay.contains("theater") || hay.contains("screen")))
        guard hit else { return nil }

        var fields: [String: String] = [
            "qr_data": qr,
            "event": "",
            "seat": "",
            "venue": "",
            "booking_id": ""
        ]
        if let seat = firstMatch(in: ticket.recognizedText, pattern: #"(?i)seat\s*[:\-]?\s*([A-Z0-9\- ]{1,12})"#) {
            fields["seat"] = seat.uppercased()
        }
        if let booking = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:booking|bms)\s*(?:id|#)?\s*[:\-]?\s*([A-Z0-9]{6,})"#) {
            fields["booking_id"] = booking.uppercased()
        }
        if let venue = firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:venue|cinema|theatre|theater)\s*[:\-]?\s*([^\n]{4,40})"#) {
            fields["venue"] = venue.trimmingCharacters(in: .whitespaces)
        }
        // Heuristic: longest Title Case-ish line as event name
        let lines = ticket.recognizedText.split(separator: "\n").map(String.init)
        if let event = lines.first(where: { $0.count > 6 && $0.rangeOfCharacter(from: .letters) != nil && !$0.lowercased().contains("seat") }) {
            fields["event"] = event.trimmingCharacters(in: .whitespaces)
        }

        var relevant: String?
        if let dateStr = firstMatch(in: ticket.recognizedText, pattern: #"(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})"#),
           let date = parseLooseDate(dateStr) {
            relevant = ISO8601DateFormatter().string(from: date.addingTimeInterval(-2 * 3600))
        }

        return result(
            templateId: "bookmyshow",
            displayName: "BookMyShow",
            confidence: hay.contains("bookmyshow") || hay.contains("book my show") ? 0.9 : 0.7,
            fields: fields,
            relevantDateISO8601: relevant,
            rationale: "Detected event / cinema ticket cues",
            ticket: ticket
        )
    }


    private static func classifyIRCTC(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("irctc")
            || hay.contains("indian railway")
            || hay.contains("e-ticket") && hay.contains("pnr")
            || (hay.contains("pnr") && (hay.contains("train") || hay.contains("coach") || hay.contains("berth")))
        guard hit else { return nil }

        let body = ticket.recognizedText
        var fields: [String: String] = [
            "qr_data": qr.isEmpty ? (firstMatch(in: body, pattern: #"(?i)pnr\s*[:\-]?\s*([0-9]{10})"#) ?? "") : qr,
            "origin": "",
            "destination": "",
            "passenger": "",
            "pnr": "",
            "train": "",
            "coach": "",
            "seat": ""
        ]
        if let pnr = firstMatch(in: body, pattern: #"(?i)pnr\s*[:\-]?\s*([0-9]{10})"#)
            ?? firstMatch(in: body, pattern: #"\b([0-9]{10})\b"#) {
            fields["pnr"] = pnr
            if fields["qr_data"]?.isEmpty == true { fields["qr_data"] = pnr }
        }
        if let train = firstMatch(in: body, pattern: #"(?i)train\s*(?:no\.?|number)?\s*[:\-]?\s*([0-9]{4,5})"#) {
            fields["train"] = train
        }
        if let coach = firstMatch(in: body, pattern: #"(?i)coach\s*[:\-]?\s*([A-Z0-9]{1,4})"#) {
            fields["coach"] = coach.uppercased()
        }
        if let berth = firstMatch(in: body, pattern: #"(?i)(?:berth|seat)\s*(?:no\.?)?\s*[:\-]?\s*([A-Z0-9]{1,4})"#) {
            fields["seat"] = berth.uppercased()
        }
        if let passenger = firstMatch(in: body, pattern: #"(?i)passenger\s*(?:name)?\s*[:\-]?\s*([A-Za-z .]{3,40})"#) {
            fields["passenger"] = passenger.trimmingCharacters(in: .whitespaces)
        }
        // Station codes often appear as FROM / TO lines
        if let origin = firstMatch(in: body, pattern: #"(?i)(?:from|boarding)\s*[:\-]?\s*([A-Z]{3,5}|[A-Za-z ]{3,24})"#) {
            fields["origin"] = origin.trimmingCharacters(in: .whitespaces)
        }
        if let dest = firstMatch(in: body, pattern: #"(?i)(?:to|destination)\s*[:\-]?\s*([A-Z]{3,5}|[A-Za-z ]{3,24})"#) {
            fields["destination"] = dest.trimmingCharacters(in: .whitespaces)
        }

        let conf = (fields["pnr"]?.isEmpty == false) ? 0.88 : 0.65
        return result(
            templateId: "irctc",
            displayName: "IRCTC Rail",
            confidence: conf,
            fields: fields,
            rationale: "Detected IRCTC / rail e-ticket cues",
            ticket: ticket
        )
    }

    private static func classifyIndigo(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("indigo")
            || hay.contains("6e-")
            || hay.contains("goindigo")
            || (hay.contains("boarding pass") && (hay.contains("6e") || hay.contains("flight")))
        guard hit else { return nil }

        let body = ticket.recognizedText
        var fields: [String: String] = [
            "qr_data": qr,
            "origin": "",
            "destination": "",
            "passenger": "",
            "flight": "",
            "seat": "",
            "pnr": "",
            "gate": ""
        ]
        if let flight = firstMatch(in: body, pattern: #"(?i)\b(6E[-\s]?\d{2,4})\b"#) {
            fields["flight"] = flight.uppercased().replacingOccurrences(of: " ", with: "")
        }
        if let pnr = firstMatch(in: body, pattern: #"(?i)(?:pnr|booking\s*ref(?:erence)?)\s*[:\-]?\s*([A-Z0-9]{6})"#) {
            fields["pnr"] = pnr.uppercased()
            if fields["qr_data"]?.isEmpty == true { fields["qr_data"] = pnr.uppercased() }
        }
        if let seat = firstMatch(in: body, pattern: #"(?i)seat\s*[:\-]?\s*([0-9]{1,2}[A-F])"#) {
            fields["seat"] = seat.uppercased()
        }
        if let gate = firstMatch(in: body, pattern: #"(?i)gate\s*[:\-]?\s*([A-Z0-9]{1,3})"#) {
            fields["gate"] = gate.uppercased()
        }
        if let passenger = firstMatch(in: body, pattern: #"(?i)(?:passenger|name)\s*[:\-]?\s*([A-Za-z .]{3,40})"#) {
            fields["passenger"] = passenger.trimmingCharacters(in: .whitespaces)
        }
        let codes = matches(in: body, pattern: #"\b([A-Z]{3})\b"#)
            .filter { !["THE","AND","FOR","PDF","PNR","SEQ","STD","ETA","GATE","IND","GST"].contains($0) }
        if codes.count >= 2 {
            fields["origin"] = codes[0]
            fields["destination"] = codes[1]
        }
        if fields["qr_data"]?.isEmpty == true, let pnr = fields["pnr"], !pnr.isEmpty {
            fields["qr_data"] = pnr
        }

        let conf = (fields["pnr"]?.isEmpty == false || !qr.isEmpty) ? 0.86 : 0.62
        return result(
            templateId: "indigo",
            displayName: "IndiGo",
            confidence: conf,
            fields: fields,
            rationale: "Detected IndiGo / flight boarding cues",
            ticket: ticket
        )
    }

    /// Generic airline/OTA boarding when brand-specific rules miss.
    private static func classifyAirlineHint(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("makemytrip")
            || hay.contains("mmt")
            || hay.contains("cleartrip")
            || hay.contains("boarding pass")
            || hay.contains("airline")
            || (hay.contains("pnr") && hay.contains("flight"))
        guard hit else { return nil }

        let body = ticket.recognizedText
        var fields: [String: String] = [
            "qr_data": qr,
            "origin": "",
            "destination": "",
            "passenger": "",
            "flight": "",
            "seat": "",
            "pnr": "",
            "gate": ""
        ]
        if let pnr = firstMatch(in: body, pattern: #"(?i)(?:pnr|booking\s*ref(?:erence)?)\s*[:\-]?\s*([A-Z0-9]{6})"#) {
            fields["pnr"] = pnr.uppercased()
            if qr.isEmpty { fields["qr_data"] = pnr.uppercased() }
        }
        if let flight = firstMatch(in: body, pattern: #"\b([A-Z]{2}\s?\d{2,4})\b"#) {
            fields["flight"] = flight.uppercased()
        }
        if let seat = firstMatch(in: body, pattern: #"(?i)seat\s*[:\-]?\s*([0-9]{1,2}[A-F])"#) {
            fields["seat"] = seat.uppercased()
        }
        let codes = matches(in: body, pattern: #"\b([A-Z]{3})\b"#)
            .filter { !["THE","AND","FOR","PDF","PNR","SEQ","STD","ETA","GST"].contains($0) }
        if codes.count >= 2 {
            fields["origin"] = codes[0]
            fields["destination"] = codes[1]
        }

        return result(
            templateId: "indigo",
            displayName: "Flight boarding",
            confidence: 0.58,
            fields: fields,
            rationale: "Detected generic airline/OTA boarding cues — using IndiGo boarding layout",
            ticket: ticket
        )
    }

    // MARK: - Helpers

    private static func result(
        templateId: String,
        displayName: String,
        confidence: Double,
        fields: [String: String],
        stationIds: [String] = [],
        relevantDateISO8601: String? = nil,
        rationale: String,
        ticket: ExtractedTicket
    ) -> ClassificationResult {
        ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: confidence,
            fields: fields,
            stationIds: stationIds,
            relevantDateISO8601: relevantDateISO8601,
            rationale: rationale,
            needsManualBrandPick: confidence < 0.5,
            extracted: ticket,
            createdAt: Date()
        )
    }

    private static func upiQueryValue(_ qr: String, key: String) -> String? {
        guard let comps = URLComponents(string: qr) else { return nil }
        return comps.queryItems?.first(where: { $0.name == key })?.value?
            .removingPercentEncoding
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        matches(in: text, pattern: pattern).first
    }

    private static func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func parseLooseDate(_ raw: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd-MM-yyyy", "dd/MM/yy", "d/M/yyyy"]
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_IN")
        for f in formats {
            parser.dateFormat = f
            if let d = parser.date(from: raw) { return d }
        }
        return nil
    }

    private struct StationRef { let id: String; let name: String }

    private static func knownNammaStations() -> [StationRef] {
        [
            .init(id: "IND", name: "Indiranagar"),
            .init(id: "MJL", name: "Majestic"),
            .init(id: "MGS", name: "Mahatma Gandhi Road"),
            .init(id: "BYP", name: "Baiyyappanahalli"),
            .init(id: "YSP", name: "Yeshwanthpur"),
            .init(id: "JYN", name: "Jayanagar"),
            .init(id: "BNR", name: "Banashankari"),
            .init(id: "CUB", name: "Cubbon Park"),
            .init(id: "VID", name: "Vidhana Soudha"),
            .init(id: "TNL", name: "Trinity"),
            .init(id: "HLN", name: "Halasuru"),
            .init(id: "SWC", name: "Swami Vivekananda Road"),
            .init(id: "JPB", name: "JP Nagar"),
            .init(id: "RJN", name: "Rajajinagar"),
            .init(id: "NAG", name: "Nagasandra"),
            .init(id: "CKM", name: "Silk Institute")
        ]
    }
}
