import ActivityKit
import Foundation

/// Shared between the Slip app and SlipWidgets Live Activity extension.
struct SlipPassActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var statusLine: String
        var detailLine: String
        /// 0...1 countdown toward relevant time when known.
        var progress: Double
    }

    var passTitle: String
    var templateId: String
    var routeOrVenue: String
}
