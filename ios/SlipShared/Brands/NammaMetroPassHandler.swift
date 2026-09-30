import Foundation

struct NammaMetroPassHandler: BrandPassHandler {
    let templateId = "namma-metro"
    let priority = 70
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        NammaMetroPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
}

enum NammaMetroPassLogic {
    private struct StationRef {
        let id: String
        let name: String
    }

    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
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
        } else if let from = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:from|origin)\s*[:\-]?\s*([A-Za-z .]{3,})"#),
                  let to = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:to|destination)\s*[:\-]?\s*([A-Za-z .]{3,})"#) {
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
        let stationIds = found.prefix(10).map { $0.id }

        return TicketText.result(
            templateId: "namma-metro",
            displayName: "Namma Metro",
            confidence: found.count >= 2 ? 0.9 : 0.72,
            fields: fields,
            stationIds: Array(stationIds),
            rationale: "Detected Namma Metro transit ticket",
            ticket: ticket
        )
    }


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
