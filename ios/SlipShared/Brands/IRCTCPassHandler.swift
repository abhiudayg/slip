import Foundation

struct IRCTCPassHandler: BrandPassHandler {
    let templateId = "irctc"
    let priority = 40
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        IRCTCPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        let qr = result.fields["qr_data"] ?? result.extracted.qrPayload ?? ""
        let parsed = IRCTCPassLogic.extractFields(from: result.extracted.recognizedText, qr: qr)
        let junkValues: Set<String> = [
            "SEAT", "BERTH", "WL", "NO", "CNF", "RAC", "STATUS", "COACH", "TRAIN", "—"
        ]
        for (key, value) in parsed where key != "_relevantDateISO8601" {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let existing = result.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let existingJunk = junkValues.contains(existing.uppercased())
            if !trimmed.isEmpty, existing.isEmpty || existingJunk {
                result.fields[key] = trimmed
            }
        }
        if let relevant = parsed["_relevantDateISO8601"], result.relevantDateISO8601 == nil {
            result.relevantDateISO8601 = relevant
        }
        return result
    }
}

enum IRCTCPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        guard looksLikeIRCTC(hay: hay, text: ticket.recognizedText) else { return nil }

        let fields = extractFields(from: ticket.recognizedText, qr: qr)
        let filled = ["pnr", "origin", "destination", "train", "passenger", "coach", "seat"]
            .filter { !(fields[$0] ?? "").isEmpty }
            .count
        let conf: Double
        if filled >= 4 { conf = 0.94 }
        else if fields["pnr"]?.isEmpty == false { conf = 0.88 }
        else { conf = 0.7 }

        var out = fields
        let relevantISO = out.removeValue(forKey: "_relevantDateISO8601")

        return TicketText.result(
            templateId: "irctc",
            displayName: "IRCTC Rail",
            confidence: conf,
            fields: out,
            stationIds: [],
            relevantDateISO8601: relevantISO,
            rationale: "Detected IRCTC / Rail Connect ticket cues",
            ticket: ticket
        )
    }

    /// Deterministic IRCTC / Rail Connect field parse (also used by enrich after AI match).
    static func extractFields(from text: String, qr: String) -> [String: String] {
        let body = text
        var fields: [String: String] = [
            "qr_data": qr,
            "origin": "",
            "destination": "",
            "passenger": "",
            "pnr": "",
            "train": "",
            "coach": "",
            "seat": "",
            "dep": "",
            "arr": "",
            "duration": "",
            "time": ""
        ]

        if let pnr = TicketText.firstMatch(in: body, pattern: #"(?i)pnr\s*(?:no\.?|number)?\s*[:\-]?\s*([0-9]{10})"#)
            ?? TicketText.firstMatch(in: body, pattern: #"(?i)pnr[^\n]{0,24}?([0-9]{10})"#) {
            fields["pnr"] = pnr
        }

        // Train: email "Train No. / Name :\n16575 /\nGOMTESHWARA\nEXP" or "NAME(16540)"
        if let trainNo = TicketText.firstMatch(
            in: body,
            pattern: #"(?i)train\s*(?:no\.?|number)?[\s\S]{0,48}?([0-9]{4,5})"#
        ) ?? TicketText.firstMatch(in: body, pattern: #"(?i)\b([0-9]{4,5})\s*/\s*[A-Z]"#)
            ?? TicketText.firstMatch(in: body, pattern: #"\(([0-9]{4,5})\)"#) {
            fields["train"] = trainNo
            // Capture name after "16575 / GOMTESHWARA EXP" (may span lines).
            if let name = TicketText.firstMatch(
                in: body,
                pattern: #"(?is)\b\#(trainNo)\s*/\s*([A-Z][A-Z0-9 \n]{2,60}?)(?=\n\s*(?:Quota|Transaction|From|Class|PNR|Date|Boarding)|$)"#
            ) ?? TicketText.firstMatch(
                in: body,
                pattern: #"([A-Z][A-Z0-9 ]{2,40}?)\s*\(\#(trainNo)\)"#
            ) {
                let cleaned = name
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count >= 3, cleaned.rangeOfCharacter(from: .letters) != nil {
                    fields["train"] = "\(cleaned) \(trainNo)"
                        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                }
            }
        }

        // Prefer explicit From / To in confirmation emails, then generic station pairs.
        if let fromTo = irctcFromToStations(from: body) {
            fields["origin"] = fromTo.origin
            fields["destination"] = fromTo.destination
        } else {
            let stations = irctcStationPairs(from: body)
            if stations.count >= 2 {
                fields["origin"] = stations[0]
                fields["destination"] = stations[1]
            } else if stations.count == 1 {
                fields["origin"] = stations[0]
            }
        }
        if fields["origin"]?.isEmpty != false,
           let origin = TicketText.firstMatch(in: body, pattern: #"(?i)(?:from|boarding)\s*[:\-]?\s*([A-Z]{2,5}|[A-Za-z ]{3,24})"#) {
            fields["origin"] = origin.trimmingCharacters(in: .whitespaces)
        }
        if fields["destination"]?.isEmpty != false,
           let dest = TicketText.firstMatch(in: body, pattern: #"(?i)(?:to|destination)\s*[:\-]?\s*([A-Z]{2,5}|[A-Za-z ]{3,24})"#) {
            fields["destination"] = dest.trimmingCharacters(in: .whitespaces)
        }

        // Coach/seat: "CNF/D1/58", "CNF D1 58", or email passenger row.
        if let status = irctcCNFStatus(from: body) {
            fields["coach"] = status.coach
            fields["seat"] = status.seat
        } else {
            if let coach = TicketText.firstMatch(in: body, pattern: #"(?i)(?:^|\s)coach\s*[:\-]?\s*([A-Z]\d{0,3})\b"#) {
                fields["coach"] = coach.uppercased()
            }
            if let berth = TicketText.firstMatch(in: body, pattern: #"(?i)(?:berth|seat)\s*(?:no\.?|/)?\s*[:\-]?\s*([0-9]{1,3}[A-Z]?)\b"#) {
                let cleaned = berth.uppercased()
                let junk: Set<String> = ["SEAT", "BERTH", "WL", "NO", "CNF", "RAC", "STATUS", "COACH"]
                if !junk.contains(cleaned) {
                    fields["seat"] = cleaned
                }
            }
        }

        // Passenger: "1 ARYAMAN MODI 23 Male …" (name may wrap across lines).
        if let passenger = TicketText.firstMatch(
            in: body,
            pattern: #"(?is)(?:passenger\s*(?:details|information)[\s\S]{0,120}?)(?:^|\n)\s*\d{1,2}\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3})"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(?m)^\s*\d{1,2}\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3})\s+\d{1,3}\s+(?:Male|Female)\b"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(?i)passenger\s*(?:name)?\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,40})"#
        ) {
            let cleaned = passenger
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = cleaned.lowercased()
            let junk = ["details", "information", "mobile", "male", "female", "age", "status"]
            if !junk.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }) {
                fields["passenger"] = cleaned
            }
        }

        if fields["qr_data"]?.isEmpty != false, let pnr = fields["pnr"], !pnr.isEmpty {
            fields["qr_data"] = pnr
        }

        // Schedule: Rail Connect "13:35 … Sun, 23 Aug … 16:30" or email "23-Aug-2026 07:00".
        applyIRCTCSchedule(to: &fields, from: body)

        return fields
    }

    static func looksLikeIRCTC(hay: String, text: String) -> Bool {
        // Self-drive / Zoomcar booking details are not rail tickets.
        if hay.contains("zoomcar")
            || hay.contains("host details")
            || hay.contains("check-in instructions")
            || hay.contains("opens 30 mins before")
            || hay.contains("rules & tips for your ride")
            || (hay.contains("check in") && hay.contains("trip start")) {
            return false
        }
        if hay.contains("irctc") || hay.contains("indian railway") || hay.contains("rail connect") {
            return true
        }
        if hay.contains("e-ticket") && hay.contains("pnr") { return true }
        if hay.contains("pnr") && (hay.contains("train") || hay.contains("coach") || hay.contains("berth")) {
            return true
        }
        // IRCTC Rail Connect app screenshots
        let railConnect =
            hay.contains("ticket details")
            || hay.contains("transaction id")
            || hay.contains("booking status")
            || hay.contains("current status")
            || hay.contains("passenger information")
            || hay.contains("tatkal")
            || hay.contains("second sitting")
            || hay.contains("cnf/")
        if hay.contains("pnr") && railConnect { return true }
        // PNR + station code in parentheses + 4–5 digit train number
        let hasPNR = TicketText.firstMatch(in: text, pattern: #"(?i)pnr\s*[:\-]?\s*[0-9]{10}"#) != nil
        let hasStationCode = TicketText.firstMatch(in: text, pattern: #"\([A-Z]{2,5}\)"#) != nil
        let hasTrainNo = TicketText.firstMatch(in: text, pattern: #"\([0-9]{4,5}\)"#) != nil
            || TicketText.firstMatch(in: text, pattern: #"(?i)train\s*(?:no\.?|number)?[\s\S]{0,48}?[0-9]{4,5}"#) != nil
        return hasPNR && hasStationCode && hasTrainNo
    }

    /// Returns display strings like "Shravanabelagola (SBGA)".
    static func irctcStationPairs(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: #"([A-Za-z][A-Za-z .]{1,40}?)\s*\(([A-Z]{2,5})\)"#
        ) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var out: [String] = []
        for match in regex.matches(in: text, range: range) {
            guard match.numberOfRanges > 2,
                  let nameR = Range(match.range(at: 1), in: text),
                  let codeR = Range(match.range(at: 2), in: text) else { continue }
            let name = String(text[nameR]).trimmingCharacters(in: .whitespaces)
            let code = String(text[codeR])
            // Skip train-number style if somehow matched; codes are letters only already.
            if name.count < 3 { continue }
            // Avoid matching forever-long lines
            let display = "\(name) (\(code))"
            if !out.contains(display) { out.append(display) }
        }
        return out
    }

    static func applyIRCTCSchedule(to fields: inout [String: String], from body: String) {
        if let duration = TicketText.firstMatch(in: body, pattern: #"(?i)\b(\d{1,2}\s*h[:\s]?\d{1,2}\s*m)\b"#) {
            var d = duration.lowercased()
            d = d.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            if d.contains("h") && !d.contains("h:") {
                d = d.replacingOccurrences(of: "h", with: "h:")
            }
            fields["duration"] = d
        }

        var times = irctcClockTimes(from: body)
        // Status bar often precedes ticket content (e.g. 16:25). Drop first when duration exists.
        if times.count >= 3,
           body.range(of: #"(?i)\d{1,2}\s*h[:\s]?\d{1,2}\s*m"#, options: .regularExpression) != nil {
            times = Array(times.dropFirst())
        }
        if times.count >= 1 { fields["dep"] = times[0] }
        if times.count >= 2 { fields["arr"] = times[1] }

        var datePart = TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(?:date\s*of\s*journey|journey\s*date)\s*[:\-]?\s*(\d{1,2}[- ](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[- ]20\d{2})"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(\d{1,2}[- ](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[- ]20\d{2})"#
        )

        if datePart == nil,
           let partial = TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*,\s*(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)"#
           ) {
            if let year = TicketText.firstMatch(in: body, pattern: #"(20\d{2})"#) {
                datePart = "\(partial) \(year)"
            } else {
                datePart = partial
            }
        }

        if let emailDep = TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(?:scheduled\s*departure\*?|departure)\s*[:\-]?\s*(\d{1,2}[-/ ](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/ ]20\d{2}\s+\d{1,2}:\d{2})"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(\d{1,2}-?(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*-?20\d{2}\s+\d{1,2}:\d{2})"#
        ) {
            let normalized = emailDep.replacingOccurrences(of: "-", with: " ")
            if fields["dep"]?.isEmpty != false,
               let full = TicketText.firstMatch(in: normalized, pattern: #"\b((?:[01]?\d|2[0-3]):[0-5]\d)\b"#) {
                let parts = full.split(separator: ":")
                if parts.count == 2 {
                    let h = parts[0], m = parts[1]
                    fields["dep"] = h.count == 1 ? "0\(h):\(m)" : "\(h):\(m)"
                } else {
                    fields["dep"] = full
                }
            }
            if datePart == nil,
               let dOnly = TicketText.firstMatch(in: normalized, pattern: #"(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+20\d{2})"#) {
                datePart = dOnly
            }
            if fields["_relevantDateISO8601"] == nil, let d = TicketText.parseLooseDateTime(normalized) {
                fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: d)
            }
        }

        if let dep = fields["dep"], !dep.isEmpty {
            if let datePart {
                let prettyDate = datePart
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                fields["time"] = "\(prettyDate) · \(dep)"
                if fields["_relevantDateISO8601"] == nil {
                    let combined = "\(prettyDate) \(dep)"
                    if let d = TicketText.parseLooseDateTime(combined) {
                        fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: d)
                    } else if let d = TicketText.parseLooseDate(prettyDate), let withClock = attachClock(dep, to: d) {
                        fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: withClock)
                    }
                } else if let d = TicketText.parseLooseDate(prettyDate), let withClock = attachClock(dep, to: d) {
                    // Prefer date+dep over date-only ISO left earlier.
                    fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: withClock)
                }
            } else {
                fields["time"] = dep
            }
        } else if let datePart {
            let prettyDate = datePart
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            fields["time"] = prettyDate
            if fields["_relevantDateISO8601"] == nil, let d = TicketText.parseLooseDate(prettyDate) {
                fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: d)
            }
        }
    }

    static func irctcClockTimes(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"\b([01]?\d|2[0-3]):([0-5]\d)\b"#) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var out: [String] = []
        for match in regex.matches(in: text, range: range) {
            guard match.numberOfRanges > 2,
                  let h = Range(match.range(at: 1), in: text),
                  let m = Range(match.range(at: 2), in: text) else { continue }
            let hour = String(text[h])
            let minute = String(text[m])
            let normalized = hour.count == 1 ? "0\(hour):\(minute)" : "\(hour):\(minute)"
            if out.last != normalized { out.append(normalized) }
        }
        return out
    }

    static func attachClock(_ hhmm: String, to date: Date) -> Date? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps)
    }

    static func irctcCNFStatus(from text: String) -> (coach: String, seat: String)? {
        // Rail Connect: CNF/D1/58/NB  ·  Email table: CNF D1 58  ·  CNF/D1/58
        let patterns = [
            #"(?i)\*?CNF\s*/\s*([A-Z0-9]{1,4})\s*/\s*([0-9]{1,3})(?:\s*/\s*[A-Z]{1,4})?"#,
            #"(?i)\bCNF\s+([A-Z][0-9]{0,3})\s+([0-9]{1,3})\b"#,
            #"(?i)\b(?:RAC|WL)\s*/\s*([A-Z0-9]{1,4})\s*/\s*([0-9]{1,3})"#
        ]
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 2,
                  let c = Range(match.range(at: 1), in: text),
                  let s = Range(match.range(at: 2), in: text) else { continue }
            return (String(text[c]).uppercased(), String(text[s]))
        }
        return nil
    }

    /// From : YESVANTPUR JN (YPR) … To : SHRAVANBELAGOLA (SBGA)
    static func irctcFromToStations(from text: String) -> (origin: String, destination: String)? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?is)From\s*:\s*([A-Za-z][A-Za-z .]{1,40}?)\s*\(([A-Z]{2,5})\)[\s\S]{0,200}?To\s*:\s*([A-Za-z][A-Za-z .]{1,40}?)\s*\(([A-Z]{2,5})\)"#
        ) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 4,
              let oName = Range(match.range(at: 1), in: text),
              let oCode = Range(match.range(at: 2), in: text),
              let dName = Range(match.range(at: 3), in: text),
              let dCode = Range(match.range(at: 4), in: text) else { return nil }
        let origin = "\(String(text[oName]).trimmingCharacters(in: .whitespaces)) (\(String(text[oCode])))"
        let destination = "\(String(text[dName]).trimmingCharacters(in: .whitespaces)) (\(String(text[dCode])))"
        return (origin, destination)
    }




    /// All passenger rows on an IRCTC / Rail Connect ticket (one Wallet pass each).
    static func extractPassengerEntries(from text: String) -> [PassengerSeatEntry] {
        var entries: [PassengerSeatEntry] = []
        let junkNames: Set<String> = [
            "details", "information", "mobile", "male", "female", "age", "status",
            "passenger", "name", "coach", "berth", "seat"
        ]

        // "1 ARYAMAN MODI 23 Male … CNF/D1/58"
        let rowPattern = #"(?im)^\s*(\d{1,2})\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3})\s+(\d{1,3})\s+(Male|Female|M|F)\b([^\n]*)"#
        for groups in TicketText.matchGroups(in: text, pattern: rowPattern) {
            guard groups.count >= 2 else { continue }
            let name = groups[1]
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = name.lowercased()
            if junkNames.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }) { continue }

            var coach = ""
            var seat = ""
            var berthType = ""
            let tail = groups.count > 4 ? groups[4] : ""
            let blob = "\(name) \(tail)"
            if let g = TicketText.matchGroups(
                in: blob,
                pattern: #"(?i)\b(?:CNF|RAC|WL)[/ ]([A-Z]\d{0,3})[/ ](\d{1,3}[A-Z]?)\b"#
            ).first, g.count >= 2 {
                coach = g[0].uppercased()
                seat = g[1].uppercased()
            } else {
                let escaped = NSRegularExpression.escapedPattern(for: name)
                let near = "(?is)" + escaped + #"[\\s\\S]{0,100}?\b(?:CNF|RAC|WL)[/ ]([A-Z]\d{0,3})[/ ](\d{1,3}[A-Z]?)\b"#
                if let g = TicketText.matchGroups(in: text, pattern: near).first, g.count >= 2 {
                    coach = g[0].uppercased()
                    seat = g[1].uppercased()
                }
            }
            if let bt = TicketText.firstMatch(
                in: tail,
                pattern: #"(?i)\b(Lower|Middle|Upper|Side\s*Lower|Side\s*Upper|Window|Aisle)\b"#
            ) {
                berthType = bt
            }
            entries.append(PassengerSeatEntry(passenger: name, coach: coach, seat: seat, berthType: berthType))
        }

        if entries.count < 2 {
            let alt = #"(?im)^\s*\d{1,2}\s+([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3})\b"#
            var seen = Set(entries.map { $0.passenger.lowercased() })
            for name in TicketText.matches(in: text, pattern: alt) {
                let cleaned = name.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                let lower = cleaned.lowercased()
                if junkNames.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }) { continue }
                if seen.contains(lower) { continue }
                seen.insert(lower)
                entries.append(PassengerSeatEntry(passenger: cleaned))
            }
        }

        return entries
    }

}
