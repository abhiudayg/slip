import Foundation
import Combine

@MainActor
final class AppClipModel: ObservableObject {
    @Published var package: PassSharePackage?
    @Published var errorMessage: String?
    @Published var isBuilding = false
    @Published var passData: Data?

    private let api = PassAPIClient()

    func consume(url: URL) {
        errorMessage = nil
        passData = nil
        guard let package = PassSharePackage.parse(from: url) else {
            errorMessage = "This Slip link isn’t valid."
            return
        }
        self.package = package
    }

    func addToWallet() async {
        guard let package else { return }
        isBuilding = true
        defer { isBuilding = false }
        do {
            let classification = package.asClassification()
            let request = CreatePassRequest(
                template: classification.templateId,
                fields: classification.fields,
                stationIds: classification.stationIds.isEmpty ? nil : classification.stationIds,
                locations: nil,
                relevantDate: classification.relevantDateISO8601,
                expirationDate: nil,
                barcodeFormat: nil,
                serialNumber: nil
            )
            passData = try await api.createPass(request)
            SlipHaptics.passSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
