import Foundation
import Combine
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var brands: [BrandSummary] = []
    @Published var stations: [Station] = []
    @Published var isLoadingBrands = false
    @Published var errorMessage: String?
    @Published var pendingClassification: ClassificationResult?
    @Published var isExtracting = false

    let api: PassAPIClient
    let appGroup = Bundle.main.object(forInfoDictionaryKey: "SlipAppGroup") as? String ?? SharedInbox.appGroupId

    init(api: PassAPIClient = PassAPIClient()) {
        self.api = api
    }

    func bootstrap() async {
        isLoadingBrands = true
        defer { isLoadingBrands = false }
        do {
            brands = try await api.fetchBrands()
            if let metro = brands.first(where: { $0.id == "namma-metro" }),
               let catalog = metro.stationCatalog {
                stations = try await api.fetchStations(catalogId: catalog).stations
            }
            consumeSharedPayloadIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            brands = BrandSummary.fallbackCatalog
            consumeSharedPayloadIfNeeded()
        }
    }

    func consumeSharedPayloadIfNeeded() {
        if let result = SharedInbox.consumeClassification() {
            pendingClassification = result
            SharedInbox.wipeAll()
            return
        }
        // Legacy barcode-only share payload
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: "slip.pending.barcode") else { return }
        defaults.removeObject(forKey: "slip.pending.barcode")
        SharedInbox.wipeAll()
        if let payload = try? JSONDecoder().decode(LegacySharedBarcode.self, from: data) {
            let extracted = TicketExtractor.extract(
                payload: payload.message,
                symbology: payload.symbology
            )
            Task { @MainActor in
                pendingClassification = await IntelligentBrandClassifier.classify(extracted)
            }
        }
    }

    func classifyScanned(payload: String, symbology: String) {
        let extracted = TicketExtractor.extract(payload: payload, symbology: symbology)
        Task { @MainActor in
            isExtracting = true
            defer { isExtracting = false }
            pendingClassification = await IntelligentBrandClassifier.classify(extracted)
        }
    }

    func classifyPDF(_ data: Data) async {
        isExtracting = true
        defer { isExtracting = false }
        let extracted = await TicketExtractor.extract(fromPDF: data)
        pendingClassification = await IntelligentBrandClassifier.classify(extracted)
    }

    func classifyImage(_ image: UIImage) async {
        isExtracting = true
        defer { isExtracting = false }
        let extracted = await TicketExtractor.extract(from: image)
        pendingClassification = await IntelligentBrandClassifier.classify(extracted)
    }

    private struct LegacySharedBarcode: Codable {
        var message: String
        var symbology: String
        var createdAt: Date
    }
}
