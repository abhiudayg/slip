import Foundation

/// Lightweight pass face for WidgetKit / watchOS (App Group). Not a vault decrypt substitute —
/// the main app publishes a curated snapshot when the vault unlocks or changes.
struct WidgetPassSnapshot: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var templateId: String
    var displayName: String
    var subtitle: String
    var qrPayload: String
    var accentRGB: String?
    var expiresAt: Date?
    var relevantAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}

enum WidgetPassStore {
    static let appGroupId = "group.com.aeswibon.slip"
    static let passesKey = "slip.widget.passes.v1"
    static let selectedIndexKey = "slip.widget.selectedIndex.v1"
    static let updatedAtKey = "slip.widget.updatedAt.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func save(_ passes: [WidgetPassSnapshot], selectedIndex: Int = 0) {
        guard let defaults else { return }
        let active = passes.filter { !$0.isExpired && !$0.qrPayload.isEmpty }
        guard let data = try? JSONEncoder().encode(active) else { return }
        defaults.set(data, forKey: passesKey)
        defaults.set(max(0, min(selectedIndex, max(0, active.count - 1))), forKey: selectedIndexKey)
        defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }

    static func load() -> [WidgetPassSnapshot] {
        guard let defaults,
              let data = defaults.data(forKey: passesKey),
              let passes = try? JSONDecoder().decode([WidgetPassSnapshot].self, from: data) else {
            return []
        }
        return passes.filter { !$0.isExpired && !$0.qrPayload.isEmpty }
    }

    static func selectedIndex() -> Int {
        defaults?.integer(forKey: selectedIndexKey) ?? 0
    }

    static func setSelectedIndex(_ index: Int) {
        let count = load().count
        guard count > 0 else {
            defaults?.set(0, forKey: selectedIndexKey)
            return
        }
        defaults?.set(((index % count) + count) % count, forKey: selectedIndexKey)
    }

    static func selectedPass() -> WidgetPassSnapshot? {
        let passes = load()
        guard !passes.isEmpty else { return nil }
        let idx = selectedIndex()
        return passes[min(max(0, idx), passes.count - 1)]
    }

    /// Sorted for Watch / Lock Screen relevance (soonest relevant first, then newest).
    static func relevanceSorted() -> [WidgetPassSnapshot] {
        load().sorted { a, b in
            switch (a.relevantAt, b.relevantAt) {
            case let (a?, b?): return a < b
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.displayName < b.displayName
            }
        }
    }
}

enum SlipDeepLink {
    static let qrHost = "qr"

    static func brightQR(passId: String) -> URL {
        URL(string: "slip://qr/\(passId)")!
    }

    static func parsePassId(from url: URL) -> String? {
        guard url.scheme == "slip" else { return nil }
        if url.host == qrHost {
            let id = url.pathComponents.filter { $0 != "/" }.first
            return id
        }
        // slip:/qr/id style
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 2, parts[0] == qrHost { return parts[1] }
        if parts.count == 1, url.host == nil { return parts[0] }
        return nil
    }
}
