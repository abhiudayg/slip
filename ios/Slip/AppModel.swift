import Foundation
import Combine
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var brands: [BrandSummary] = []
    @Published var stations: [Station] = []
    @Published var isLoadingBrands = false
    @Published var errorMessage: String?
    /// Brand pick step — OCR/QR done, field extraction not yet.
    @Published var pendingImport: PendingImport?
    /// After brand confirmed + extraction — review/edit fields.
    @Published var pendingClassification: ClassificationResult?
    /// Multi-traveler expansion (IRCTC 4 pax, IndiGo multi-stub PDF, …).
    @Published var pendingBatch: ClassificationBatch?
    @Published var isExtracting = false
    /// Overlay copy while OCR vs field extraction.
    @Published var extractingStatus: String = "Reading ticket"
    @Published var isJailbroken = false

    let api: PassAPIClient
    let appGroup = Bundle.main.object(forInfoDictionaryKey: "SlipAppGroup") as? String ?? SharedInbox.appGroupId

    init(api: PassAPIClient = PassAPIClient()) {
        self.api = api
        self.isJailbroken = Self.checkJailbreak()
    }

    private static func checkJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let suspiciousFiles = [
            "/Applications/Cydia.app",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        for file in suspiciousFiles {
            if FileManager.default.fileExists(atPath: file) {
                return true
            }
        }
        let testPath = "/private/jailbreak.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
        #endif
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
            // Share extension already classified — skip brand step and open confirm.
            presentClassification(result)
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
                presentBrandStep(for: extracted)
            }
        }
    }

    func classifyScanned(payload: String, symbology: String) {
        let extracted = TicketExtractor.extract(payload: payload, symbology: symbology)
        Task { @MainActor in
            presentBrandStep(for: extracted)
        }
    }

    func classifyPDF(_ data: Data) async {
        extractingStatus = "Reading ticket"
        isExtracting = true
        defer { isExtracting = false }
        let extracted = await TicketExtractor.extract(fromPDF: data)
        presentBrandStep(for: extracted)
    }

    func classifyImage(_ image: UIImage) async {
        extractingStatus = "Reading ticket"
        isExtracting = true
        defer { isExtracting = false }
        if let swatch = TicketColorExtractor.extract(from: image) {
            TicketColorExtractor.cacheLast(swatch)
        }
        let extracted = await TicketExtractor.extract(from: image)
        presentBrandStep(for: extracted)
    }

    /// Rules/AI brand guess only — field extraction waits for confirmBrandAndExtract.
    func presentBrandStep(for ticket: ExtractedTicket) {
        let suggestion = IntelligentBrandClassifier.suggestBrand(ticket)
        pendingImport = PendingImport(ticket: ticket, suggestion: suggestion)
    }

    /// User confirmed brand → run brand-specific extraction (+ on-device AI fill).
    func confirmBrandAndExtract(templateId: String) async {
        guard let pending = pendingImport else { return }
        let ticket = pending.ticket
        // Dismiss brand sheet before overlay / confirm sheet to avoid stacked presentation glitches.
        pendingImport = nil
        extractingStatus = "Extracting pass fields"
        isExtracting = true
        defer { isExtracting = false }
        let result = await IntelligentBrandClassifier.classify(
            ticket,
            forcedTemplateId: templateId
        )
        // Let brand sheet finish dismissing.
        try? await Task.sleep(nanoseconds: 320_000_000)
        presentClassification(result)
    }

    /// Expand multi-passenger tickets into separate confirm/create passes.
    func presentClassification(_ result: ClassificationResult) {
        let items = PassTravelerSplit.expand(result)
        if items.count > 1 {
            pendingBatch = ClassificationBatch(items: items)
            pendingClassification = nil
        } else {
            pendingBatch = nil
            pendingClassification = items.first ?? result
        }
    }

    func clearPendingClassification() {
        pendingClassification = nil
        pendingBatch = nil
    }

    /// Import a pass shared via `slip://import/…` (iMessage / AirDrop / Universal Link).
    func importSharePackage(_ package: PassSharePackage) {
        let result = BrandPassRegistry.enrich(package.asClassification())
        presentClassification(result)
        SlipHaptics.scanSuccess()
    }

    private struct LegacySharedBarcode: Codable {
        var message: String
        var symbology: String
        var createdAt: Date
    }
}
