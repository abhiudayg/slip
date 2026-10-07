import AppIntents
import Foundation

enum SlipSiriHandoff {
    static let pendingPassIdKey = "slip.siri.pendingPassId"

    static func queueOpen(passId: String) {
        UserDefaults(suiteName: SharedInbox.appGroupId)?.set(passId, forKey: pendingPassIdKey)
        UserDefaults.standard.set(passId, forKey: pendingPassIdKey)
    }

    static func consumePendingPassId() -> String? {
        let suite = UserDefaults(suiteName: SharedInbox.appGroupId)
        let id = suite?.string(forKey: pendingPassIdKey)
            ?? UserDefaults.standard.string(forKey: pendingPassIdKey)
        suite?.removeObject(forKey: pendingPassIdKey)
        UserDefaults.standard.removeObject(forKey: pendingPassIdKey)
        let trimmed = id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// Exposes vault passes to Siri / Spotlight as first-class App Entities (iOS 27 Apple Intelligence).
struct SlipPassEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Slip Pass")
    static var defaultQuery = SlipPassEntityQuery()

    var id: String
    var displayName: String
    var templateId: String
    var subtitle: String
    var qrPayload: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(subtitle.isEmpty ? BrandPassRegistry.friendlyName(for: templateId) : subtitle)"
        )
    }

    static func from(snapshot: WidgetPassSnapshot) -> SlipPassEntity {
        SlipPassEntity(
            id: snapshot.id,
            displayName: snapshot.displayName,
            templateId: snapshot.templateId,
            subtitle: snapshot.subtitle,
            qrPayload: snapshot.qrPayload
        )
    }
}

struct SlipPassEntityQuery: EntityStringQuery {
    func entities(for identifiers: [SlipPassEntity.ID]) async throws -> [SlipPassEntity] {
        let all = Self.loadEntities()
        let wanted = Set(identifiers)
        return all.filter { wanted.contains($0.id) }
    }

    func suggestedEntities() async throws -> [SlipPassEntity] {
        Array(Self.loadEntities().prefix(12))
    }

    func entities(matching string: String) async throws -> [SlipPassEntity] {
        let q = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return try await suggestedEntities() }
        return Self.loadEntities().filter { entity in
            entity.displayName.lowercased().contains(q)
                || entity.subtitle.lowercased().contains(q)
                || entity.templateId.lowercased().contains(q)
                || BrandPassRegistry.friendlyName(for: entity.templateId).lowercased().contains(q)
        }
    }

    private static func loadEntities() -> [SlipPassEntity] {
        WidgetPassStore.load().map(SlipPassEntity.from(snapshot:))
    }
}

/// “Hey Siri, show my Slip pass…”
struct ShowSlipPassIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Slip Pass"
    static var description = IntentDescription("Open a pass from your Slip vault — works with semantic search.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Pass")
    var pass: SlipPassEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SlipSiriHandoff.queueOpen(passId: pass.id)
        return .result(dialog: IntentDialog(stringLiteral: "Opening \(pass.displayName) in Slip."))
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$pass) in Slip")
    }
}

/// Find a pass by brand, city, movie, or flight.
struct FindSlipPassIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Slip Pass"
    static var description = IntentDescription("Search your Slip vault by brand, city, movie, or flight.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Query", description: "e.g. BookMyShow tonight, flight to Bangalore, IRCTC")
    var query: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let matches = try await SlipPassEntityQuery().entities(matching: query)
        guard let first = matches.first else {
            return .result(dialog: IntentDialog(stringLiteral: "No Slip pass matched “\(query)”."))
        }
        SlipSiriHandoff.queueOpen(passId: first.id)
        let more = matches.count > 1 ? " (\(matches.count) matches)" : ""
        return .result(
            dialog: IntentDialog(stringLiteral: "Found \(first.displayName)\(more). Opening Slip.")
        )
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Find Slip pass matching \(\.$query)")
    }
}
