import ActivityKit
import Foundation

/// Starts / ends Dynamic Island + Lock Screen Live Activities for a Slip pass.
@MainActor
enum PassLiveActivityController {
    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @discardableResult
    static func start(from classification: ClassificationResult) -> Bool {
        guard areActivitiesEnabled else { return false }

        let title = classification.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let passTitle = title.isEmpty ? "Slip Pass" : title
        let route = routeLine(from: classification)
        let status = statusLine(from: classification)
        let detail = detailLine(from: classification)
        let progress = progressValue(from: classification)

        let attributes = SlipPassActivityAttributes(
            passTitle: passTitle,
            templateId: classification.templateId,
            routeOrVenue: route
        )
        let state = SlipPassActivityAttributes.ContentState(
            statusLine: status,
            detailLine: detail,
            progress: progress
        )

        let stale = Calendar.current.date(byAdding: .hour, value: 12, to: Date())
        do {
            // End any prior Slip activities so Island stays tidy.
            for activity in Activity<SlipPassActivityAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            let content = ActivityContent(state: state, staleDate: stale)
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            return true
        } catch {
            return false
        }
    }

    static func endAll() {
        for activity in Activity<SlipPassActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .after(.now + 2)) }
        }
    }

    private static func routeLine(from classification: ClassificationResult) -> String {
        let fields = classification.fields
        if let o = nonEmpty(fields["origin"]), let d = nonEmpty(fields["destination"]) {
            return "\(shortCode(o)) → \(shortCode(d))"
        }
        if let event = nonEmpty(fields["event"]) { return event }
        if let property = nonEmpty(fields["property"]) { return property }
        if let venue = nonEmpty(fields["venue"]) { return venue }
        return classification.templateId.isEmpty ? "Pass" : classification.templateId
    }

    private static func statusLine(from classification: ClassificationResult) -> String {
        if let train = nonEmpty(classification.fields["train"]) { return train }
        if let flight = nonEmpty(classification.fields["flight"]) { return flight }
        if let pnr = nonEmpty(classification.fields["pnr"]) { return "PNR \(pnr)" }
        if let booking = nonEmpty(classification.fields["booking_id"]) { return booking }
        return "Ready on Lock Screen"
    }

    private static func detailLine(from classification: ClassificationResult) -> String {
        let coach = nonEmpty(classification.fields["coach"])
        let seat = nonEmpty(classification.fields["seat"])
        if let coach, let seat { return "Coach \(coach) · Seat \(seat)" }
        if let seat { return "Seat \(seat)" }
        if let passenger = nonEmpty(classification.fields["passenger"]) { return passenger }
        if let checkIn = nonEmpty(classification.fields["check_in"]) { return "Check-in \(checkIn)" }
        if let iso = classification.relevantDateISO8601, let date = ISO8601DateFormatter().date(from: iso) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_IN")
            f.dateFormat = "EEE, d MMM · HH:mm"
            return f.string(from: date)
        }
        return classification.rationale.isEmpty ? "Slip Live Activity" : classification.rationale
    }

    private static func progressValue(from classification: ClassificationResult) -> Double {
        guard let iso = classification.relevantDateISO8601,
              let target = ISO8601DateFormatter().date(from: iso) else { return 0.35 }
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -6, to: target) ?? now
        let total = target.timeIntervalSince(start)
        guard total > 0 else { return 0.5 }
        let elapsed = now.timeIntervalSince(start)
        return min(1, max(0, elapsed / total))
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func shortCode(_ text: String) -> String {
        if let paren = text.split(separator: "(").last?.split(separator: ")").first, paren.count <= 5 {
            return String(paren).uppercased()
        }
        return String(text.prefix(8))
    }
}
