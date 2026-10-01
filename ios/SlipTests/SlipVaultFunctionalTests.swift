import XCTest
@testable import Slip

@MainActor
final class SlipVaultFunctionalTests: XCTestCase {

    var vaultStore: PassVaultStore!

    override func setUpWithError() throws {
        vaultStore = PassVaultStore(inMemory: true)
    }

    override func tearDownWithError() throws {
        vaultStore = nil
    }

    func testPassCreationAndRetrieval() throws {
        let payload = PassVaultPayload(
            templateId: "zomato",
            displayName: "The Table - Zomato Gold",
            fields: ["restaurant": "The Table", "time": "9:30 PM", "party_size": "2"],
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Zomato dining pass",
            confidence: 0.95,
            qrPayload: "https://zoma.to/r/123",
            barcodeSymbology: "QR",
            recognizedText: "The Table 9:30 PM"
        )

        let record = try vaultStore.save(payload: payload, walletAdded: false)
        XCTAssertEqual(record.templateId, "zomato")
        XCTAssertEqual(record.displayName, "The Table - Zomato Gold")
        XCTAssertTrue(vaultStore.records.contains { $0.id == record.id })
    }

    func testPassDeletion() throws {
        let payload = PassVaultPayload(
            templateId: "bookmyshow",
            displayName: "Dune: Part Two",
            fields: ["event": "Dune: Part Two", "venue": "PVR Director's Cut", "seat": "F14"],
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Movie ticket",
            confidence: 0.98,
            qrPayload: "BMS:DUNE2:F14",
            barcodeSymbology: "QR",
            recognizedText: "Dune: Part Two PVR"
        )

        let record = try vaultStore.save(payload: payload, walletAdded: false)
        XCTAssertTrue(vaultStore.records.contains { $0.id == record.id })

        try vaultStore.delete(record)
        XCTAssertFalse(vaultStore.records.contains { $0.id == record.id })
    }
}
