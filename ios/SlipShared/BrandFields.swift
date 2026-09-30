import Foundation

/// Canonical per-brand pass field schema — sourced from Stitch
/// `apple_wallet_template_*/code.html` layouts (all visible face fields).
enum BrandFields {
    struct Schema {
        var required: [String]
        var optional: [String]

        var all: [String] { required + optional }
        var allowed: Set<String> { Set(all) }
    }

    /// Place name / address used for Wallet `locations` + app geofencing.
    static let geofenceKeys = ["location", "latitude", "longitude"]

    static func schema(for templateId: String) -> Schema {
        withGeofenceFields(baseSchema(for: templateId))
    }

    private static func withGeofenceFields(_ schema: Schema) -> Schema {
        var optional = schema.optional
        for key in geofenceKeys where !schema.allowed.contains(key) {
            optional.append(key)
        }
        return Schema(required: schema.required, optional: optional)
    }

    private static func baseSchema(for templateId: String) -> Schema {
        switch templateId {
        case "bookmyshow":
            // Stitch: movie, format/cert, theatre, audi/screen, date, showtime, seats, booking, F&B, pickup
            return Schema(
                required: ["event", "seat", "qr_data"],
                optional: [
                    "venue", "screen", "booking_id", "time", "date", "format",
                    "certification", "language", "fnb", "pickup_counter"
                ]
            )
        case "district":
            // Stitch festival: tier, event, venue, date/gates, fast entry, zone, passholder, wristband, cashless
            return Schema(
                required: ["event", "qr_data"],
                optional: [
                    "venue", "seat", "screen", "tier", "gate", "zone",
                    "passholder", "booking_id", "time", "date", "format",
                    "age_gate", "cashless_balance", "venue_detail", "access"
                ]
            )
        case "irctc":
            // Stitch: train, quota/class, stations+platforms, duration/distance, PNR, passenger, coach/berth, dep/arr, chart
            return Schema(
                required: ["origin", "destination", "qr_data"],
                optional: [
                    "passenger", "pnr", "train", "coach", "seat", "berth_type",
                    "dep", "arr", "duration", "time", "date", "class", "quota",
                    "pnr_status", "origin_platform", "dest_platform", "distance",
                    "chart_status"
                ]
            )
        case "indigo":
            // Stitch: flight, stations+terminals, duration/status, passenger, class/tier, dep/board/gate/seat, PNR, zone
            return Schema(
                required: ["origin", "destination", "qr_data"],
                optional: [
                    "passenger", "flight", "seat", "pnr", "gate",
                    "dep", "arr", "board_time", "duration", "time", "date",
                    "origin_terminal", "dest_terminal", "terminal", "class",
                    "loyalty_tier", "status", "boarding_zone"
                ]
            )
        case "namma-metro":
            // Stitch: line, ticket type, origin/platform, stops/duration/fare, dest/exits, token, issued/valid
            return Schema(
                required: ["origin", "destination", "qr_data"],
                optional: [
                    "passenger", "dep", "arr", "time", "duration", "booking_id",
                    "line", "ticket_type", "fare", "origin_platform", "exit_gates",
                    "stops", "issued_at", "valid_till"
                ]
            )
        case "redbus":
            // Stitch: PNR, operator, bus #, boarding/drop, dep/arr, seat type, passenger, driver
            return Schema(
                required: ["origin", "destination", "qr_data"],
                optional: [
                    "passenger", "seat", "seat_type", "pnr", "bus", "bus_operator",
                    "bus_number", "dep", "arr", "duration", "time", "date",
                    "boarding_point", "drop_point", "driver_contact", "dep_label",
                    "arr_label"
                ]
            )
        case "upi":
            // Stitch: holder, VPA, bank, a/c mask, txn limit, autopay, IFSC, status
            return Schema(
                required: ["name", "qr_data"],
                optional: [
                    "vpa", "bank", "amount", "note", "account_mask",
                    "txn_limit", "autopay_limit", "ifsc", "status"
                ]
            )
        case "easydiner":
            // Stitch Prime store card: discount, offer, venue, table/time, member, tier, valid
            return Schema(
                required: ["restaurant", "booking_id"],
                optional: [
                    "time", "date", "party_size", "table", "qr_data", "guest",
                    "discount", "offer", "points", "member_id", "valid_thru",
                    "tier", "status"
                ]
            )
        case "zomato-dineout":
            // Stitch reservation: party, venue/city, date/slot, table area, name, booking, special, cuisine
            return Schema(
                required: ["restaurant", "booking_id"],
                optional: [
                    "time", "date", "party_size", "table", "table_area", "qr_data",
                    "guest", "city", "special_tag", "cuisine", "grace_period"
                ]
            )
        case "swiggy-dineout":
            // Stitch coupon: offer code, discount, bank offer, venue, valid, min order, One status
            return Schema(
                required: ["restaurant", "booking_id"],
                optional: [
                    "time", "date", "party_size", "table", "qr_data", "guest",
                    "offer_code", "discount", "bank_offer", "area", "valid_till",
                    "min_order", "membership_status"
                ]
            )
        case "airbnb":
            // Stitch room key: property, location, check-in/out times, guest+details, PIN, wifi, lock
            return Schema(
                required: ["property", "booking_id"],
                optional: [
                    "property_type", "address", "city", "check_in", "check_out",
                    "check_in_time", "check_out_time", "guest", "guest_details",
                    "door_pin", "host", "host_badge", "lock_brand", "wifi_ssid",
                    "wifi_password", "status", "qr_data"
                ]
            )
        case "zoomcar":
            // Stitch keyless: vehicle, plate, fuel/range, pickup hub, drop, PIN, driver, km, SOS
            return Schema(
                required: ["vehicle", "booking_id"],
                optional: [
                    "pickup", "drop_off", "guest", "plate", "qr_data", "fuel",
                    "range_km", "pickup_hub", "rental_duration", "door_pin",
                    "key_status", "dl_verified", "km_limit", "roadside",
                    "vehicle_type"
                ]
            )
        case "cult":
            // Stitch creation dashboard: member, center, plan, valid, check-ins, member id
            return Schema(
                required: ["name", "qr_data"],
                optional: [
                    "membership", "center", "plan", "valid_thru", "checkins",
                    "member_id", "status"
                ]
            )
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
        seedGeofenceFields(&out, templateId: templateId)
        return out
    }

    /// Prefer an explicit `location`; otherwise copy from the brand's place-like field.
    static func seedGeofenceFields(_ fields: inout [String: String], templateId: String) {
        let current = fields["location"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard current.isEmpty else { return }
        let preferred: [String]
        switch templateId {
        case "airbnb": preferred = ["address", "property", "city"]
        case "bookmyshow", "district": preferred = ["venue", "venue_detail"]
        case "irctc", "indigo", "namma-metro", "redbus": preferred = ["destination", "origin", "boarding_point"]
        case "zoomcar": preferred = ["pickup_hub", "pickup", "drop_off"]
        case "easydiner", "zomato-dineout", "swiggy-dineout": preferred = ["restaurant", "area", "city"]
        case "cult": preferred = ["center"]
        default: preferred = ["venue", "address", "property", "restaurant", "origin", "city"]
        }
        for key in preferred {
            if let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                fields["location"] = v
                return
            }
        }
    }

    static func parseCoordinate(_ raw: String?) -> Double? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
              let value = Double(raw), value.isFinite else { return nil }
        return value
    }

    /// Accepts `"12.97, 77.59"` style coords typed into the location field.
    static func parseLatLonPair(_ raw: String?) -> (Double, Double)? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        let parts = raw.split(whereSeparator: { ",;/".contains($0) }).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard parts.count >= 2,
              let lat = Double(parts[0]), let lon = Double(parts[1]),
              (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        return (lat, lon)
    }

    /// Best free-text query for geocoding when lat/lon are absent.
    static func geocodeQuery(from fields: [String: String]) -> String? {
        let keys = ["location", "address", "venue", "venue_detail", "property", "pickup_hub",
                    "pickup", "restaurant", "destination", "origin", "center", "city"]
        for key in keys {
            if let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty,
               parseLatLonPair(v) == nil {
                return v
            }
        }
        return nil
    }

    static func label(for key: String, templateId: String = "") -> String {
        switch key {
        case "qr_data": return "QR / barcode payload"
        case "booking_id":
            switch templateId {
            case "airbnb": return "Confirmation / pass code"
            case "district": return "Wristband / booking ID"
            case "namma-metro": return "Token / pass ID"
            default: return "Booking ID"
            }
        case "event": return "Movie / event"
        case "venue": return "Theatre / venue"
        case "venue_detail": return "Venue detail / map"
        case "screen": return "Audi / screen"
        case "seat":
            return ["bookmyshow", "district"].contains(templateId) ? "Seats" : "Seat / berth"
        case "seat_type": return "Seat type"
        case "time":
            switch templateId {
            case "bookmyshow", "district": return "Showtime / gates"
            case "easydiner", "zomato-dineout", "swiggy-dineout": return "Reservation time"
            default: return "Time"
            }
        case "date": return "Date"
        case "format": return "Format (IMAX / Dolby)"
        case "certification": return "Certification (U/A…)"
        case "language": return "Language / version"
        case "fnb": return "F&B combo"
        case "pickup_counter": return "F&B pickup counter"
        case "property": return "Property"
        case "property_type": return "Stay type"
        case "location": return "Location (geofence)"
        case "latitude": return "Latitude"
        case "longitude": return "Longitude"
        case "address": return "Address / area"
        case "city": return "City"
        case "check_in": return "Check-in date"
        case "check_out": return "Check-out date"
        case "check_in_time": return "Check-in time"
        case "check_out_time": return "Check-out time"
        case "guest":
            switch templateId {
            case "zoomcar": return "Driver"
            case "airbnb": return "Guest / reserved for"
            default: return "Guest"
            }
        case "guest_details": return "Guests • bedrooms"
        case "door_pin": return "Backup door / car PIN"
        case "host": return "Host"
        case "host_badge": return "Host badge (Superhost)"
        case "lock_brand": return "Lock brand"
        case "wifi_ssid": return "Wi‑Fi name"
        case "wifi_password": return "Wi‑Fi password"
        case "status": return "Status"
        case "vpa": return "UPI ID (VPA)"
        case "account_mask": return "Account mask"
        case "txn_limit": return "Txn limit / day"
        case "autopay_limit": return "Auto-pay limit"
        case "ifsc": return "IFSC"
        case "drop_off": return "Drop-off"
        case "drop_point": return "Drop-off point"
        case "pickup": return "Pickup"
        case "pickup_hub": return "Pickup hub"
        case "vehicle": return "Vehicle"
        case "vehicle_type": return "Vehicle type"
        case "plate": return "Registration / plate"
        case "fuel": return "Fuel / range"
        case "range_km": return "Range (km)"
        case "rental_duration": return "Rental duration"
        case "key_status": return "Key status"
        case "dl_verified": return "DL verified"
        case "km_limit": return "Kilometer limit"
        case "roadside": return "Roadside assist"
        case "bank": return "Bank"
        case "bank_offer": return "Bank offer"
        case "amount": return "Amount"
        case "note": return "Note"
        case "restaurant": return "Restaurant / venue"
        case "party_size": return "Party size"
        case "table": return "Table"
        case "table_area": return "Table area"
        case "special_tag": return "Special tag"
        case "cuisine": return "Cuisine"
        case "grace_period": return "Grace period"
        case "discount": return "Discount"
        case "offer": return "Offer / perk"
        case "offer_code": return "Offer code"
        case "points": return "Points perk"
        case "member_id": return "Member ID"
        case "valid_thru": return "Valid thru"
        case "valid_till": return "Valid till"
        case "min_order": return "Min. order value"
        case "membership_status": return "Membership status"
        case "area": return "Area / locality"
        case "passenger": return "Passenger"
        case "pnr": return "PNR"
        case "pnr_status": return "PNR status"
        case "train": return "Train no. & name"
        case "coach": return "Coach"
        case "berth_type": return "Berth type (Window…)"
        case "class": return "Class"
        case "quota": return "Quota"
        case "flight": return "Flight"
        case "gate":
            return templateId == "district" ? "Fast entry / gate" : "Gate"
        case "terminal": return "Terminal"
        case "origin_terminal": return "Origin terminal"
        case "dest_terminal": return "Destination terminal"
        case "board_time": return "Boarding time"
        case "loyalty_tier": return "Loyalty tier"
        case "boarding_zone": return "Boarding zone"
        case "dep": return "Depart"
        case "arr": return "Arrive"
        case "dep_label": return "Depart label (Tonight…)"
        case "arr_label": return "Arrive label (Tomorrow…)"
        case "duration": return "Duration"
        case "distance": return "Distance"
        case "bus": return "Bus"
        case "bus_operator": return "Bus operator"
        case "bus_number": return "Bus number"
        case "boarding_point": return "Boarding point"
        case "driver_contact": return "Driver contact"
        case "line": return "Metro line"
        case "ticket_type": return "Ticket type"
        case "fare": return "Fare"
        case "origin_platform": return "Origin platform"
        case "dest_platform": return "Destination platform"
        case "exit_gates": return "Exit gates"
        case "stops": return "Stops"
        case "issued_at": return "Issued at"
        case "chart_status": return "Chart status"
        case "tier": return "Tier"
        case "zone": return "Zone"
        case "passholder": return "Passholder"
        case "age_gate": return "Age gate (21+…)"
        case "cashless_balance": return "Cashless balance"
        case "access": return "Access level"
        case "origin": return "From / origin"
        case "destination": return "To / destination"
        case "name": return templateId == "cult" ? "Member name" : "Payee / name"
        case "membership": return "Membership"
        case "center": return "Gym center"
        case "plan": return "Plan"
        case "checkins": return "Check-ins"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    static func idCaption(for templateId: String) -> String {
        switch templateId {
        case "upi": return "UPI ID"
        case "bookmyshow", "district", "easydiner", "zomato-dineout", "swiggy-dineout": return "BOOKING ID"
        case "irctc", "indigo", "redbus": return "PNR"
        case "airbnb": return "RESERVATION"
        case "zoomcar": return "BOOKING"
        case "cult": return "MEMBER ID"
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
