import Foundation
import UserNotifications

/// Local notifications: “You have a flight tomorrow. Add / open in Slip?”
@MainActor
enum BookingReminderScheduler {
    static let categoryId = "slip.booking.reminder"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private static let scheduledIdsKey = "slip.reminder.scheduledIds"

    static func reschedule(from vault: PassVaultStore) async {
        let center = UNUserNotificationCenter.current()
        let prior = UserDefaults.standard.stringArray(forKey: scheduledIdsKey) ?? []
        if !prior.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: prior)
        }

        _ = await requestAuthorization()

        let importAction = UNNotificationAction(
            identifier: "slip.booking.import.action",
            title: "Add to Slip",
            options: [.foreground]
        )
        let importCat = UNNotificationCategory(
            identifier: BookingInboxWatcher.categoryId,
            actions: [importAction],
            intentIdentifiers: [],
            options: []
        )
        let reminderCat = UNNotificationCategory(
            identifier: categoryId,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([importCat, reminderCat])

        var scheduled: [String] = []

        for record in vault.records where !record.isExpired {
            guard let payload = try? vault.decrypt(record) else { continue }
            guard let iso = payload.relevantDateISO8601,
                  let when = ISO8601DateFormatter().date(from: iso) else { continue }
            // Notify ~18h before relevant time (evening-before for morning flights).
            let fire = when.addingTimeInterval(-18 * 3600)
            guard fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = reminderTitle(templateId: payload.templateId)
            content.body = reminderBody(payload: payload, record: record)
            content.sound = .default
            content.categoryIdentifier = categoryId
            content.userInfo = ["passId": record.id]

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = "slip.reminder.\(record.id)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(req)
            scheduled.append(id)
        }
        UserDefaults.standard.set(scheduled, forKey: scheduledIdsKey)
    }

    private static func reminderTitle(templateId: String) -> String {
        switch templateId {
        case "indigo", "makemytrip", "cleartrip", "yatra": return "Flight coming up"
        case "irctc": return "Train tomorrow"
        case "bookmyshow": return "Movie night"
        case "district": return "Event tomorrow"
        case "airbnb": return "Check-in soon"
        default: return "Upcoming Slip pass"
        }
    }

    private static func reminderBody(payload: PassVaultPayload, record: PassVaultRecord) -> String {
        switch payload.templateId {
        case "indigo":
            let route = [payload.fields["origin"], payload.fields["destination"]].compactMap { $0 }.joined(separator: " → ")
            return "You have a flight\(route.isEmpty ? "" : " (\(route))"). Open Slip for your boarding pass?"
        case "irctc":
            return "Your IRCTC ticket is coming up. Open Slip to show your QR at the station."
        case "bookmyshow", "district":
            let event = payload.fields["event"] ?? record.displayName
            return "\(event) is soon. Add or open the pass in Slip?"
        default:
            return "\(record.displayName) is coming up. Open Slip?"
        }
    }
}
