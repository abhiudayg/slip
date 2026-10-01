import Foundation

/// Lightweight keyword classifiers for expanded Indian brand catalogue.
struct KeywordPassHandler: BrandPassHandler {
    let templateId: String
    let displayName: String
    let priority: Int
    let keywords: [String]
    let seedFields: [String: String]

    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool {
        keywords.contains { hay.contains($0) }
    }

    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        guard matches(qr: qr, hay: hay, ticket: ticket) else { return nil }
        var fields = seedFields
        if !qr.isEmpty { fields["qr_data"] = qr }
        return TicketText.result(
            templateId: templateId,
            displayName: displayName,
            confidence: 0.72,
            fields: fields,
            rationale: "Detected \(displayName) cues",
            ticket: ticket
        )
    }
}

enum CatalogueHandlers {
    static let all: [BrandPassHandler] = [
        KeywordPassHandler(
            templateId: "makemytrip", displayName: "MakeMyTrip", priority: 56,
            keywords: ["makemytrip", "make my trip", "mmt-"],
            seedFields: ["origin": "", "destination": "", "status": "CONFIRMED"]
        ),
        KeywordPassHandler(
            templateId: "cleartrip", displayName: "Cleartrip", priority: 57,
            keywords: ["cleartrip"],
            seedFields: ["origin": "", "destination": "", "status": "CONFIRMED"]
        ),
        KeywordPassHandler(
            templateId: "yatra", displayName: "Yatra", priority: 58,
            keywords: ["yatra.com", "yatra "],
            seedFields: ["origin": "", "destination": "", "status": "CONFIRMED"]
        ),
        KeywordPassHandler(
            templateId: "uts", displayName: "UTS Unreserved", priority: 71,
            keywords: ["uts unreserved", "uts app", "unreserved ticketing"],
            seedFields: ["origin": "", "destination": "", "ticket_type": "UTS"]
        ),
        KeywordPassHandler(
            templateId: "chalo", displayName: "Chalo Bus", priority: 72,
            keywords: ["chalo bus", "chalo app", "chalo ticket"],
            seedFields: ["origin": "", "destination": "", "ticket_type": "City Bus"]
        ),
        KeywordPassHandler(
            templateId: "uber", displayName: "Uber", priority: 25,
            keywords: ["uber trip", "uber.com", "uber premier", "uber airport"],
            seedFields: ["pickup": "", "status": "CONFIRMED", "service": "Uber"]
        ),
        KeywordPassHandler(
            templateId: "ola", displayName: "Ola", priority: 26,
            keywords: ["ola cabs", "olacabs", "ola outstation", "ola ride"],
            seedFields: ["pickup": "", "status": "CONFIRMED", "service": "Ola"]
        ),
        KeywordPassHandler(
            templateId: "golds-gym", displayName: "Gold's Gym", priority: 111,
            keywords: ["gold's gym", "golds gym", "goldsgym"],
            seedFields: ["name": "", "status": "ACTIVE", "membership": "All Clubs Access"]
        ),
        KeywordPassHandler(
            templateId: "tata-neu", displayName: "Tata Neu", priority: 120,
            keywords: ["tata neu", "tataneu", "neu pass"],
            seedFields: ["name": "", "store": "Tata Neu", "tier": "NeuPass"]
        ),
        KeywordPassHandler(
            templateId: "reliance-smart", displayName: "Reliance Smart", priority: 121,
            keywords: ["reliance smart", "smart bazaar"],
            seedFields: ["name": "", "store": "Reliance Smart"]
        ),
        KeywordPassHandler(
            templateId: "shoppers-stop", displayName: "Shoppers Stop", priority: 122,
            keywords: ["shoppers stop", "first citizen"],
            seedFields: ["name": "", "store": "Shoppers Stop", "tier": "First Citizen"]
        ),
        KeywordPassHandler(
            templateId: "bigbasket", displayName: "BigBasket", priority: 123,
            keywords: ["bigbasket", "big basket", "bbstar"],
            seedFields: ["name": "", "store": "BigBasket", "offer": "bbstar"]
        )
    ]
}
