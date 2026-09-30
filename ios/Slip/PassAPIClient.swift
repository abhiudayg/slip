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
        case "everyday_pay": return "qrcode"
        case "travel": return "airplane.departure"
        default: return "wallet.pass.fill"
        }
    }

    /// Offline-only safety net when pass-engine is unreachable. Prefer live `/v1/brands`.
    static let fallbackCatalog: [BrandSummary] = [
        BrandSummary(id: "upi", displayName: "UPI Get Paid", category: "everyday_pay", appleStyle: "generic",
                     requiredFields: ["name", "qr_data"], optionalFields: [], supportsLocations: false,
                     supportsRelevantDate: false, accentHint: "rgb(16, 185, 129)", stationCatalog: nil,
                     summary: "Personal UPI QR for receiving payments from Wallet.", badge: "UPI", iconHint: "qrcode"),
        BrandSummary(id: "cult", displayName: "Cult.fit", category: "fitness", appleStyle: "storeCard",
                     requiredFields: ["name", "qr_data"], optionalFields: ["membership"], supportsLocations: true,
                     supportsRelevantDate: false, accentHint: "rgb(255, 0, 128)", stationCatalog: nil,
                     summary: "Gym membership barcode for turnstiles and center check-in.", badge: "Fitness",
                     iconHint: "figure.run"),
        BrandSummary(id: "namma-metro", displayName: "Namma Metro", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"], optionalFields: ["passenger"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(124, 58, 237)",
                     stationCatalog: "namma-metro",
                     summary: "Bangalore metro QR tickets with station geofence surfacing.", badge: "Transit",
                     iconHint: "tram.fill"),
        BrandSummary(id: "bookmyshow", displayName: "BookMyShow", category: "entertainment", appleStyle: "eventTicket",
                     requiredFields: ["event", "seat", "qr_data"], optionalFields: ["venue", "booking_id"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(220, 38, 38)",
                     stationCatalog: nil,
                     summary: "Cinema and event tickets with seat and booking QR.", badge: "Event",
                     iconHint: "ticket.fill"),
        BrandSummary(id: "indigo", displayName: "IndiGo", category: "travel", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "flight", "seat", "pnr", "gate"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(10, 132, 255)",
                     stationCatalog: nil,
                     summary: "Flight boarding passes from IndiGo booking PDFs and screenshots.",
                     badge: "Flight", iconHint: "airplane.departure"),
        BrandSummary(id: "irctc", displayName: "IRCTC Rail", category: "transit", appleStyle: "boardingPass",
                     requiredFields: ["origin", "destination", "qr_data"],
                     optionalFields: ["passenger", "pnr", "train", "coach", "seat"],
                     supportsLocations: true, supportsRelevantDate: true, accentHint: "rgb(94, 92, 230)",
                     stationCatalog: nil,
                     summary: "IRCTC e-tickets from booking PDFs with PNR and coach details.",
                     badge: "Rail", iconHint: "train.side.front.car")
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
    var barcodeFormat: String?
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

final class PassAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(session: URLSession = .shared) {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SlipAPIBaseURL") as? String
            ?? "http://127.0.0.1:8080"
        self.baseURL = URL(string: raw)!
        self.session = session
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
