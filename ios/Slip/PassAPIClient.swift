import Foundation

struct BrandSummary: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let category: String
    let appleStyle: String
    let requiredFields: [String]
    let optionalFields: [String]
    let supportsLocations: Bool
    let supportsRelevantDate: Bool
    let accentHint: String?
    let stationCatalog: String?
    let summary: String?
    let badge: String?
    let iconHint: String?

    var categoryTitle: String {
        switch category {
        case "everyday_pay": return "Everyday pay"
        case "fitness": return "Fitness"
        case "transit": return "Transit"
        case "entertainment": return "Entertainment"
        case "dining": return "Dining"
        case "retail": return "Retail"
        default: return category.capitalized
        }
    }

    var sfSymbol: String {
        if let iconHint, !iconHint.isEmpty { return iconHint }
        switch category {
        case "transit": return "tram.fill"
        case "fitness": return "figure.run"
        case "entertainment": return "ticket.fill"
        case "dining": return "fork.knife"
        case "everyday_pay": return "qrcode"
        case "travel": return "airplane.departure"
        default: return "wallet.pass.fill"
        }
    }

    /// Offline-only safety net when pass-engine is unreachable. Prefer live `/v1/brands`.
    static let fallbackCatalog: [BrandSummary] = [
        BrandSummary(id: "irctc", displayName: "IRCTC Rail", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "pnr", "train", "coach", "seat"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(94, 92, 230)",
                     stationCatalog: nil,
                     summary: "IRCTC e-tickets from booking PDFs with PNR and coach details.",
                     badge: "Rail", iconHint: "train.side.front.car"),
        BrandSummary(id: "bookmyshow", displayName: "BookMyShow", category: "entertainment", appleStyle: "eventTicket",
                     requiredFields: ["event", "seat", "qr_data"], optionalFields: ["venue", "booking_id", "time"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(220, 38, 38)",
                     stationCatalog: nil,
                     summary: "Cinema and event tickets with seat and booking QR.", badge: "Event",
                     iconHint: "ticket.fill"),
        BrandSummary(id: "district", displayName: "District", category: "entertainment", appleStyle: "eventTicket",
                     requiredFields: ["event", "qr_data"],
                     optionalFields: ["venue", "seat", "tier", "gate", "zone", "passholder", "booking_id", "time"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(124, 58, 237)",
                     stationCatalog: nil,
                     summary: "District festival and nightlife NFC wristband passes.", badge: "Festival",
                     iconHint: "bolt.fill"),
        BrandSummary(id: "indigo", displayName: "IndiGo", category: "travel", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "flight", "seat", "pnr", "gate"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(10, 132, 255)",
                     stationCatalog: nil,
                     summary: "Flight boarding passes from IndiGo booking PDFs and screenshots.",
                     badge: "Flight", iconHint: "airplane.departure"),
        BrandSummary(id: "easydiner", displayName: "EazyDiner", category: "dining", appleStyle: "storeCard",
                     requiredFields: ["restaurant", "booking_id"],
                     optionalFields: ["time", "party_size", "qr_data"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(255, 107, 0)",
                     stationCatalog: nil,
                     summary: "EazyDiner Prime VIP store card for restaurant reservations.", badge: "VIP",
                     iconHint: "fork.knife"),
        BrandSummary(id: "zomato-dineout", displayName: "Zomato Dineout", category: "dining", appleStyle: "storeCard",
                     requiredFields: ["restaurant", "booking_id"],
                     optionalFields: ["time", "party_size", "qr_data"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(226, 55, 68)",
                     stationCatalog: nil,
                     summary: "Zomato Dineout restaurant reservations and offers.", badge: "Dining",
                     iconHint: "fork.knife.circle.fill"),
        BrandSummary(id: "swiggy-dineout", displayName: "Swiggy Dineout", category: "dining", appleStyle: "storeCard",
                     requiredFields: ["restaurant", "booking_id"],
                     optionalFields: ["time", "party_size", "qr_data"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(252, 128, 25)",
                     stationCatalog: nil,
                     summary: "Swiggy Dineout table bookings and deals.", badge: "Dining",
                     iconHint: "fork.knife"),
        BrandSummary(id: "airbnb", displayName: "Airbnb", category: "travel", appleStyle: "storeCard",
                     requiredFields: ["property", "booking_id"],
                     optionalFields: ["property_type", "address", "city", "check_in", "check_out",
                                      "check_in_time", "check_out_time", "guest", "guest_details",
                                      "door_pin", "wifi_ssid", "qr_data", "location", "latitude", "longitude"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(255, 56, 92)",
                     stationCatalog: nil,
                     summary: "Airbnb room key & access pass with check-in details.", badge: "Room Key",
                     iconHint: "house.fill"),
        BrandSummary(id: "namma-metro", displayName: "Namma Metro", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "dep", "arr", "time", "duration"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(124, 58, 237)",
                     stationCatalog: "namma-metro",
                     summary: "Namma Metro QR single-journey tickets with station geofence surfacing.",
                     badge: "Metro", iconHint: "tram.fill"),
        BrandSummary(id: "upi", displayName: "UPI PayPass", category: "everyday_pay", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"], optionalFields: ["vpa", "bank"], supportsLocations: false,
                     supportsRelevantDate: false, accentHint: "rgb(249, 115, 22)", stationCatalog: nil,
                     summary: "UPI receive/pay QR (Bharat QR / NPCI) for Apple Wallet.", badge: "UPI", iconHint: "qrcode"),
        BrandSummary(id: "redbus", displayName: "redBus", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "seat", "pnr", "bus", "dep", "arr", "duration", "time"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(216, 67, 21)",
                     stationCatalog: nil,
                     summary: "Intercity bus tickets with seat, PNR, and live boarding window.",
                     badge: "Bus", iconHint: "bus.fill"),
        BrandSummary(id: "zoomcar", displayName: "Zoomcar", category: "travel", appleStyle: "generic",
                     requiredFields: ["vehicle", "booking_id"],
                     optionalFields: ["pickup", "drop_off", "guest", "qr_data"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(132, 204, 22)",
                     stationCatalog: nil,
                     summary: "Zoomcar keyless self-drive pass with pickup and unlock details.",
                     badge: "Keyless", iconHint: "car.fill"),
        BrandSummary(id: "cult", displayName: "Cult.fit", category: "fitness", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["membership", "center", "plan", "valid_thru", "member_id", "status"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(230, 46, 72)",
                     stationCatalog: nil, summary: "Cult.fit gym access QR for centre check-in.",
                     badge: "Gym", iconHint: "figure.run"),
        BrandSummary(id: "golds-gym", displayName: "Gold's Gym", category: "fitness", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["membership", "center", "plan", "valid_thru", "member_id", "status"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(217, 173, 56)",
                     stationCatalog: nil, summary: "Gold's Gym membership access pass.",
                     badge: "Gym", iconHint: "dumbbell.fill"),
        BrandSummary(id: "makemytrip", displayName: "MakeMyTrip", category: "travel", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "pnr", "flight", "dep", "arr", "date"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(64, 115, 242)",
                     stationCatalog: nil, summary: "MakeMyTrip flight and trip booking passes.",
                     badge: "Travel", iconHint: "suitcase.fill"),
        BrandSummary(id: "cleartrip", displayName: "Cleartrip", category: "travel", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "pnr", "flight", "dep", "arr", "date"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(249, 115, 22)",
                     stationCatalog: nil, summary: "Cleartrip booking passes for flights and hotels.",
                     badge: "Travel", iconHint: "suitcase.fill"),
        BrandSummary(id: "yatra", displayName: "Yatra", category: "travel", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "pnr", "flight", "dep", "arr", "date"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(234, 88, 12)",
                     stationCatalog: nil, summary: "Yatra trip and flight e-passes.",
                     badge: "Travel", iconHint: "suitcase.fill"),
        BrandSummary(id: "uts", displayName: "UTS Unreserved", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "date", "time", "class", "fare"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(37, 99, 235)",
                     stationCatalog: nil, summary: "Indian Railways UTS unreserved QR tickets.",
                     badge: "UTS", iconHint: "tram.fill"),
        BrandSummary(id: "chalo", displayName: "Chalo Bus", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "time", "fare", "ticket_type"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(16, 185, 129)",
                     stationCatalog: nil, summary: "Chalo city bus QR tickets.",
                     badge: "Bus", iconHint: "bus.fill"),
        BrandSummary(id: "uber", displayName: "Uber", category: "travel", appleStyle: "generic",
                     requiredFields: ["pickup", "qr_data"],
                     optionalFields: ["drop_off", "vehicle", "driver", "ride_pin", "eta", "booking_id"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(0, 0, 0)",
                     stationCatalog: nil, summary: "Uber scheduled and airport ride passes.",
                     badge: "Ride", iconHint: "car.fill"),
        BrandSummary(id: "ola", displayName: "Ola", category: "travel", appleStyle: "generic",
                     requiredFields: ["pickup", "qr_data"],
                     optionalFields: ["drop_off", "vehicle", "driver", "ride_pin", "eta", "booking_id"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(34, 197, 94)",
                     stationCatalog: nil, summary: "Ola ride and outstation booking passes.",
                     badge: "Ride", iconHint: "car.fill"),
        BrandSummary(id: "tata-neu", displayName: "Tata Neu", category: "retail", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["store", "offer", "points", "tier", "member_id"],
                     supportsLocations: true, supportsRelevantDate: false, accentHint: "rgb(139, 92, 246)",
                     stationCatalog: nil, summary: "Tata Neu loyalty and store offers.",
                     badge: "Loyalty", iconHint: "n.circle.fill"),
        BrandSummary(id: "reliance-smart", displayName: "Reliance Smart", category: "retail", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["store", "offer", "points", "tier", "member_id"],
                     supportsLocations: true, supportsRelevantDate: false, accentHint: "rgb(249, 115, 22)",
                     stationCatalog: nil, summary: "Reliance Smart grocery loyalty pass.",
                     badge: "Loyalty", iconHint: "cart.fill"),
        BrandSummary(id: "shoppers-stop", displayName: "Shoppers Stop", category: "retail", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["store", "offer", "points", "tier", "member_id"],
                     supportsLocations: true, supportsRelevantDate: false, accentHint: "rgb(124, 58, 237)",
                     stationCatalog: nil, summary: "First Citizen loyalty pass for Shoppers Stop.",
                     badge: "Loyalty", iconHint: "bag.fill"),
        BrandSummary(id: "bigbasket", displayName: "BigBasket", category: "retail", appleStyle: "coupon",
                     requiredFields: ["name", "qr_data"],
                     optionalFields: ["store", "offer", "offer_code", "discount", "valid_till"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(132, 204, 22)",
                     stationCatalog: nil, summary: "BigBasket coupon and membership offers.",
                     badge: "Coupon", iconHint: "leaf.fill"),
    ]
}

struct Station: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let line: String
    let latitude: Double
    let longitude: Double
}

struct StationCatalog: Codable {
    let id: String
    let name: String
    let city: String
    let stations: [Station]
}

struct PassLocation: Codable {
    let latitude: Double
    let longitude: Double
    let relevantText: String?
}

struct CreatePassRequest: Codable {
    var template: String
    var fields: [String: String]
    var locations: [PassLocation]?
    var stationIds: [String]?
    var relevantDate: String?
    var expirationDate: String?
    var barcodeFormat: String?
    /// Stable PassKit serial — reuse when regenerating so Apple Wallet updates in place.
    var serialNumber: String?
}

enum PassAPIError: LocalizedError {
    case badURL
    case server(String)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid API URL"
        case .server(let msg): return msg
        case .emptyBody: return "Empty response from pass engine"
        }
    }
}

struct HealthResponse: Codable, Hashable {
    let status: String
    let service: String
    let devMode: Bool
}

final class PassAPIClient {
    static let shared = PassAPIClient()

    private let baseURL: URL
    private let session: URLSession

    /// OCI Always Free pass-engine (Neon-backed). Prefer Info.plist `SlipAPIBaseURL`.
    static let cloudDefaultBaseURL = "http://161.33.86.15:8080"

    var baseURLString: String { baseURL.absoluteString }

    init(session: URLSession = .shared) {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SlipAPIBaseURL") as? String
            ?? Self.cloudDefaultBaseURL
        self.baseURL = URL(string: raw) ?? URL(string: Self.cloudDefaultBaseURL)!
        self.session = session
    }

    func fetchHealth() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("v1/health")
        let (data, response) = try await session.data(from: url)
        try Self.throwIfNeeded(response, data: data)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    func fetchBrands() async throws -> [BrandSummary] {
        let url = baseURL.appendingPathComponent("v1/brands")
        let (data, response) = try await session.data(from: url)
        try Self.throwIfNeeded(response, data: data)
        return try JSONDecoder().decode([BrandSummary].self, from: data)
    }

    func fetchStations(catalogId: String) async throws -> StationCatalog {
        let url = baseURL.appendingPathComponent("v1/stations/\(catalogId)")
        let (data, response) = try await session.data(from: url)
        try Self.throwIfNeeded(response, data: data)
        return try JSONDecoder().decode(StationCatalog.self, from: data)
    }

    func createPass(_ request: CreatePassRequest) async throws -> Data {
        let url = baseURL.appendingPathComponent("v1/passes")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)
        let (data, response) = try await session.data(for: req)
        try Self.throwIfNeeded(response, data: data)
        guard !data.isEmpty else { throw PassAPIError.emptyBody }
        return data
    }


    func registerLiveActivity(
        activityId: String,
        pushToken: String,
        templateId: String,
        displayName: String
    ) async throws {
        let url = baseURL.appendingPathComponent("v1/live-activities")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Encodable {
            var activityId: String
            var pushToken: String
            var templateId: String
            var displayName: String
        }
        req.httpBody = try JSONEncoder().encode(
            Body(activityId: activityId, pushToken: pushToken, templateId: templateId, displayName: displayName)
        )
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.throwIfNeeded(response, data: data)
    }

    private static func throwIfNeeded(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            if let err = try? JSONDecoder().decode(ServerError.self, from: data) {
                throw PassAPIError.server(err.message)
            }
            throw PassAPIError.server("HTTP \(http.statusCode)")
        }
    }

    private struct ServerError: Codable {
        let message: String
    }
}
