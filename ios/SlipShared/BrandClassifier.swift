import Foundation

/// Facade over per-brand `BrandPassHandler`s.
/// Prefer calling `BrandPassRegistry` / handlers directly for new code.
enum BrandClassifier {
    static func classify(_ ticket: ExtractedTicket) -> ClassificationResult {
        BrandPassRegistry.classify(ticket)
    }

    // MARK: - Back-compat extractors (delegate to brand handlers)

    static func extractIRCTCFields(from text: String, qr: String) -> [String: String] {
        IRCTCPassLogic.extractFields(from: text, qr: qr)
    }

    static func extractBookMyShowFields(from body: String, qr: String) -> [String: String] {
        BookMyShowPassLogic.extractFields(from: body, qr: qr)
    }

    static func cinemaSeatList(from body: String) -> String? {
        BookMyShowPassLogic.cinemaSeatList(from: body)
    }

    static func extractDiningFields(from text: String, qr: String) -> [String: String] {
        DiningPassLogic.extractFields(from: text, qr: qr)
    }

    static func extractZoomcarFields(from text: String, qr: String) -> [String: String] {
        ZoomcarPassLogic.extractFields(from: text, qr: qr)
    }
}
