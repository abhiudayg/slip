import Foundation

/// Canonical per-brand pass field schema. Edit UI and Wallet create must use only these keys.
enum BrandFields {
    struct Schema {
        var required: [String]
        var optional: [String]

        var all: [String] { required + optional }
        var allowed: Set<String> { Set(all) }
    }

    static func schema(for templateId: String) -> Schema {
        switch templateId {
        case "bookmyshow":
            return Schema(required: ["event", "seat", "qr_data"], optional: ["venue", "booking_id", "time"])
        case "district":
            return Schema(required: ["event", "qr_data"], optional: ["venue", "seat", "tier", "gate", "zone", "passholder", "booking_id", "time"])
        case "irctc":
            return Schema(required: ["origin", "destination", "qr_data"], optional: ["passenger", "pnr", "train", "coach", "seat", "dep", "arr", "duration", "time"])
        case "indigo":
            return Schema(required: ["origin", "destination", "qr_data"], optional: ["passenger", "flight", "seat", "pnr", "gate", "dep", "arr", "time"])
        case "namma-metro":
            return Schema(required: ["origin", "destination", "qr_data"], optional: ["passenger", "dep", "arr", "time", "duration"])
        case "redbus":
            return Schema(required: ["origin", "destination", "qr_data"], optional: ["passenger", "seat", "pnr", "bus", "dep", "arr", "duration", "time"])
        case "upi":
            return Schema(required: ["name", "qr_data"], optional: ["vpa", "bank"])
        case "easydiner", "zomato-dineout", "swiggy-dineout":
            // Dining confirmations rarely include a QR — booking ID is the Wallet barcode.
            return Schema(required: ["restaurant", "booking_id"], optional: ["time", "party_size", "qr_data"])
        case "airbnb":
            // Room key: property + confirmation; door PIN optional; QR often absent.
            return Schema(required: ["property", "booking_id"], optional: ["check_in", "check_out", "guest", "door_pin", "qr_data"])
        case "zoomcar":
            // Self-drive confirmations rarely include a QR — booking id / plate is the barcode.
            return Schema(required: ["vehicle", "booking_id"], optional: ["pickup", "drop_off", "guest", "qr_data"])
        default:
            return Schema(required: ["qr_data"], optional: [])
        }
    }

    static func prune(_ fields: [String: String], templateId: String) -> [String: String] {
        let allowed = schema(for: templateId).allowed
        var out: [String: String] = [:]
        for (key, value) in fields where allowed.contains(key) {
            out[key] = value
        }
        for key in schema(for: templateId).all where out[key] == nil {
            out[key] = ""
        }
        return out
    }

    static func idCaption(for templateId: String) -> String {
        switch templateId {
        case "upi": return "UPI ID"
        case "bookmyshow", "district", "easydiner", "zomato-dineout", "swiggy-dineout": return "BOOKING ID"
        case "irctc", "indigo", "redbus": return "PNR"
        case "airbnb": return "RESERVATION"
        case "zoomcar": return "BOOKING"
        default: return "PASS ID"
        }
    }

    static func previewStyle(for templateId: String, appleStyle: String?) -> PreviewStyle {
        if templateId == "upi" { return .upi }
        if templateId == "bookmyshow" || templateId == "district" || appleStyle == "eventTicket" { return .event }
        if ["irctc", "indigo", "namma-metro", "redbus"].contains(templateId) || appleStyle == "boardingPass" {
            return .route
        }
        return .generic
    }

    enum PreviewStyle {
        case event, route, upi, generic
    }
}
