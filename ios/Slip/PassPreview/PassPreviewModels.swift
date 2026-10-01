import Foundation

/// Typed extraction over pass field dictionaries (BrandFields keys + legacy aliases).
enum PassFieldBag {
    static func value(_ fields: [String: String], _ keys: [String], fallback: String = "—") -> String {
        for key in keys {
            if let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
        }
        return fallback
    }

    static func join(_ parts: [String], separator: String = "\n") -> String {
        parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "—" }
            .joined(separator: separator)
    }

    static func pair(_ primary: String, _ secondary: String, separator: String = " · ") -> String {
        join([primary, secondary], separator: separator)
    }

    static func abbreviate(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 4 { return t.uppercased() }
        if let paren = t.split(separator: "(").last?.split(separator: ")").first, paren.count <= 4 {
            return String(paren).uppercased()
        }
        return String(t.prefix(3)).uppercased()
    }

    static func nonEmpty(_ value: String) -> String? {
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t.isEmpty || t == "—") ? nil : t
    }
}

struct PassBackRow: Identifiable, Hashable {
    var id: String { label + "|" + value }
    var label: String
    var value: String
}

/// Flip-side rows: everything with a value that is not on the Wallet face.
enum PassBackContent {
    static func rows(brandId: String, fields: [String: String]) -> [PassBackRow] {
        let front = BrandFields.faceFrontKeys(for: brandId)
        var rows: [PassBackRow] = []
        var seenLabels = Set<String>()
        var seenValues = Set<String>()
        // Values already shown on the face — avoid repeating identical strings on flip.
        for key in front {
            if let v = PassFieldBag.nonEmpty(fields[key] ?? "") {
                seenValues.insert(v.lowercased())
            }
        }
        for key in BrandFields.faceBackKeys(for: brandId) {
            guard !front.contains(key) else { continue }
            guard let raw = fields[key], let value = PassFieldBag.nonEmpty(raw) else { continue }
            let label = BrandFields.label(for: key, templateId: brandId)
            let labelKey = label.lowercased()
            let valueKey = value.lowercased()
            if seenLabels.contains(labelKey) { continue }
            if seenValues.contains(valueKey) { continue }
            seenLabels.insert(labelKey)
            seenValues.insert(valueKey)
            rows.append(PassBackRow(label: label, value: value))
        }
        return rows
    }
}

struct BoardingFaceModel {
    var fromCode: String
    var fromName: String
    var fromDesc: String?
    var toCode: String
    var toName: String
    var toDesc: String?
    var headerLeft: (String, String)
    var headerRight: (String, String)
    var midLeft: (String, String)
    var midRight: (String, String)
    var extraLeft: (String, String)?
    var extraRight: (String, String)?
    var footer: String?
    var duration: String
    var barcodeAlt: String
    var barcodeCaption: String
}

struct DiningFaceModel {
    var restaurant: String
    var headerLeft: (String, String)
    var headerRight: (String, String)?
    var midLeft: (String, String)?
    var midRight: (String, String)?
    var extraLeft: (String, String)?
    var extraRight: (String, String)?
    var booking: String
    var footer: String
    var badge: String?
}

struct EventFaceModel {
    var title: String
    var venueLine: String
    var whenLine: String
    var seatLine: String
    var booking: String
    var badge: String?
    var extras: [(String, String)]
}


extension BoardingFaceModel {
    static func irctc(_ fields: [String: String]) -> BoardingFaceModel {
        let origin = PassFieldBag.value(fields, ["origin"], fallback: "KSR Bengaluru (SBC)")
        let dest = PassFieldBag.value(fields, ["destination"], fallback: "MGR Chennai Ctrl (MAS)")
        let coach = PassFieldBag.value(fields, ["coach"], fallback: "C2")
        let seat = PassFieldBag.value(fields, ["seat"], fallback: "44")
        let dep = PassFieldBag.value(fields, ["dep", "departTime", "time"], fallback: "15:10")
        let date = PassFieldBag.value(fields, ["date"], fallback: "")
        // Face: route + train + depart + coach/seat + passenger. Platforms/quota/chart → flip.
        return BoardingFaceModel(
            fromCode: PassFieldBag.abbreviate(origin),
            fromName: origin,
            fromDesc: nil,
            toCode: PassFieldBag.abbreviate(dest),
            toName: dest,
            toDesc: nil,
            headerLeft: ("Train", PassFieldBag.value(fields, ["train"], fallback: "12640 • Brindavan Superfast Express")),
            headerRight: ("Depart", PassFieldBag.pair(date, dep)),
            midLeft: ("Coach / Berth", "\(coach) / \(seat)"),
            midRight: ("Passenger", PassFieldBag.value(fields, ["passenger"], fallback: "Rohit Kumar")),
            extraLeft: nil,
            extraRight: nil,
            footer: nil,
            duration: PassFieldBag.value(fields, ["duration"], fallback: "—"),
            barcodeAlt: PassFieldBag.value(fields, ["pnr", "qr_data"], fallback: "4829-1092-81"),
            barcodeCaption: "Official TTE scanner QR"
        )
    }


    static func indigo(_ fields: [String: String]) -> BoardingFaceModel {
        let origin = PassFieldBag.value(fields, ["origin"], fallback: "BLR")
        let dest = PassFieldBag.value(fields, ["destination"], fallback: "DEL")
        let dep = PassFieldBag.value(fields, ["dep", "departTime", "time"], fallback: "07:15")
        let date = PassFieldBag.value(fields, ["date"], fallback: "")
        // Face: airports + flight + depart + gate/seat + passenger. Terminals/tier/zone → flip.
        return BoardingFaceModel(
            fromCode: origin.uppercased(),
            fromName: PassFieldBag.value(fields, ["originName"], fallback: origin),
            fromDesc: nil,
            toCode: dest.uppercased(),
            toName: PassFieldBag.value(fields, ["destName"], fallback: dest),
            toDesc: nil,
            headerLeft: ("Flight", PassFieldBag.value(fields, ["flight"], fallback: "6E 2134")),
            headerRight: ("Depart", PassFieldBag.pair(date, dep)),
            midLeft: ("Gate · Seat", "\(PassFieldBag.value(fields, ["gate"], fallback: "14B")) · \(PassFieldBag.value(fields, ["seat"], fallback: "4F"))"),
            midRight: ("Passenger", PassFieldBag.value(fields, ["passenger"], fallback: "KUMAR / ROHIT MR")),
            extraLeft: nil,
            extraRight: nil,
            footer: nil,
            duration: PassFieldBag.value(fields, ["duration"], fallback: "—"),
            barcodeAlt: PassFieldBag.value(fields, ["pnr", "qr_data"], fallback: "L9QZ8W"),
            barcodeCaption: "IATA BCBP · e-ticket scan"
        )
    }


    static func redbus(_ fields: [String: String]) -> BoardingFaceModel {
        let origin = PassFieldBag.value(fields, ["origin"], fallback: "Bengaluru (BLR)")
        let dest = PassFieldBag.value(fields, ["destination", "dest"], fallback: "Hyderabad (HYD)")
        let dep = PassFieldBag.value(fields, ["dep", "departTime", "time"], fallback: "22:30")
        let date = PassFieldBag.value(fields, ["date"], fallback: "")
        let seat = PassFieldBag.value(fields, ["seat"], fallback: "U4 (Upper)")
        // Face: cities + PNR + depart + seat + passenger. Boarding points/driver/bus → flip.
        return BoardingFaceModel(
            fromCode: PassFieldBag.abbreviate(origin),
            fromName: origin,
            fromDesc: nil,
            toCode: PassFieldBag.abbreviate(dest),
            toName: dest,
            toDesc: nil,
            headerLeft: ("PNR", PassFieldBag.value(fields, ["pnr"], fallback: "TS82910471")),
            headerRight: ("Depart", PassFieldBag.pair(date, dep)),
            midLeft: ("Seat", seat),
            midRight: ("Passenger", PassFieldBag.value(fields, ["passenger"], fallback: "Rohit K.")),
            extraLeft: nil,
            extraRight: nil,
            footer: nil,
            duration: PassFieldBag.value(fields, ["duration"], fallback: "—"),
            barcodeAlt: PassFieldBag.value(fields, ["pnr", "qr_data"], fallback: "TS82910471"),
            barcodeCaption: "Boarding QR"
        )
    }

}


extension DiningFaceModel {
    static func easydiner(_ fields: [String: String]) -> DiningFaceModel {
        let party = PassFieldBag.value(fields, ["party_size"], fallback: "")
        let time = PassFieldBag.value(fields, ["time"], fallback: "21:00")
        let date = PassFieldBag.value(fields, ["date"], fallback: "")
        let reservation = PassFieldBag.pair(
            party.isEmpty || party == "—" ? "" : "Table for \(party)",
            PassFieldBag.pair(date, time)
        )
        return DiningFaceModel(
            restaurant: PassFieldBag.value(fields, ["restaurant"], fallback: "The Table • Colaba"),
            headerLeft: ("Discount", PassFieldBag.value(fields, ["discount"], fallback: "25% OFF")),
            headerRight: ("Reservation", reservation.isEmpty ? time : reservation),
            midLeft: ("Guest", PassFieldBag.value(fields, ["guest", "name"], fallback: "Rohit Kumar")),
            midRight: nil,
            extraLeft: nil,
            extraRight: nil,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "ED-992014-PR"),
            footer: "Scan at bill settlement",
            badge: PassFieldBag.value(fields, ["discount"], fallback: "25% OFF")
        )
    }


    static func zomato(_ fields: [String: String]) -> DiningFaceModel {
        let party = PassFieldBag.value(fields, ["party_size", "guests"], fallback: "4")
        let date = PassFieldBag.value(fields, ["date"], fallback: "")
        let time = PassFieldBag.value(fields, ["time"], fallback: "Tonight, 20:30")
        return DiningFaceModel(
            restaurant: PassFieldBag.value(fields, ["restaurant"], fallback: "Bastian • At The Top"),
            headerLeft: ("Party", party.contains("Guest") ? party : "\(party) Guests"),
            headerRight: ("Date & Time", PassFieldBag.pair(date, time)),
            midLeft: ("Guest", PassFieldBag.value(fields, ["guest", "name"], fallback: "Rohit Kumar")),
            midRight: nil,
            extraLeft: nil,
            extraRight: nil,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "ZOM-94821"),
            footer: "Show at hostess podium",
            badge: "Reservation"
        )
    }


    static func swiggy(_ fields: [String: String]) -> DiningFaceModel {
        let offer = PassFieldBag.value(fields, ["offer_code"], fallback: "DINEOUT30")
        let discount = PassFieldBag.value(fields, ["discount"], fallback: "FLAT 30% OFF")
        let valid = PassFieldBag.value(fields, ["valid_till", "time"], fallback: "Valid Tonight")
        return DiningFaceModel(
            restaurant: PassFieldBag.value(fields, ["restaurant"], fallback: "Toit Brewpub • Indiranagar"),
            headerLeft: ("Offer", offer),
            headerRight: ("Validity", valid),
            midLeft: ("Discount", discount),
            midRight: nil,
            extraLeft: nil,
            extraRight: nil,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "SWIGGY-TOIT-309482"),
            footer: "Scan or present to server",
            badge: discount.contains("%") ? discount : "FLAT 30% OFF"
        )
    }

}

extension EventFaceModel {
    static func bookmyshow(_ fields: [String: String]) -> EventFaceModel {
        let event = PassFieldBag.value(fields, ["event"], fallback: "Dune: Part Two")
        let venue = PassFieldBag.value(fields, ["venue"], fallback: "PVR INOX • Forum Mall Koramangala")
        let seat = PassFieldBag.value(fields, ["seat"], fallback: "E12, E13, E14")
        let time = PassFieldBag.value(fields, ["time"], fallback: "19:45")
        let date = PassFieldBag.value(fields, ["date"], fallback: "Fri, 27 Oct")
        // Face: movie + venue + showtime + seats. Format/F&B/language → flip.
        return EventFaceModel(
            title: event,
            venueLine: venue,
            whenLine: PassFieldBag.pair(date, time),
            seatLine: seat,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "W7B9KLM"),
            badge: nil,
            extras: []
        )
    }


    static func district(_ fields: [String: String]) -> EventFaceModel {
        let event = PassFieldBag.value(fields, ["event"], fallback: "Sunburn Arena • Bengaluru")
        let venue = PassFieldBag.value(fields, ["venue"], fallback: "Manpho Convention Center")
        let gate = PassFieldBag.value(fields, ["gate"], fallback: "Gate 3 • VIP Express")
        let time = PassFieldBag.value(fields, ["time"], fallback: "16:00 Onwards")
        let date = PassFieldBag.value(fields, ["date"], fallback: "Sat, 04 Nov")
        let tier = PassFieldBag.value(fields, ["tier"], fallback: "VIP PIT PASS")
        let booking = PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "DST-77192")
        // Face: event + venue + when + entry. Zone/cashless/passholder → flip.
        return EventFaceModel(
            title: event,
            venueLine: venue,
            whenLine: PassFieldBag.pair(date, time),
            seatLine: gate,
            booking: booking,
            badge: tier,
            extras: [("Tier", tier), ("Fast Entry", gate)]
        )
    }

}

struct KeylessFaceModel {
    var title: String
    var subtitleBadge: String?
    var status: String
    var primaryLeft: (String, String)
    var primaryRight: (String, String)
    var secondaryLeft: (String, String)
    var secondaryRight: (String, String)
    var tertiaryLeft: (String, String)
    var tertiaryRight: (String, String)
    var footerLeft: (String, String)?
    var footerRight: (String, String)?
    var booking: String
    var nfcTitle: String
    var nfcSubtitle: String
}

extension KeylessFaceModel {
    static func airbnb(_ fields: [String: String]) -> KeylessFaceModel {
        let guest = PassFieldBag.value(fields, ["guest"], fallback: "—")
        return KeylessFaceModel(
            title: PassFieldBag.value(fields, ["property"], fallback: "Villa Sol • Candolim Beach"),
            subtitleBadge: PassFieldBag.value(fields, ["property_type"], fallback: ""),
            status: PassFieldBag.value(fields, ["status"], fallback: "ACTIVE"),
            primaryLeft: ("Check-In", PassFieldBag.pair(
                PassFieldBag.value(fields, ["check_in"], fallback: "Thu, 24 Oct"),
                PassFieldBag.value(fields, ["check_in_time"], fallback: "14:00 onwards")
            )),
            primaryRight: ("Check-Out", PassFieldBag.pair(
                PassFieldBag.value(fields, ["check_out"], fallback: "Mon, 28 Oct"),
                PassFieldBag.value(fields, ["check_out_time"], fallback: "11:00 am")
            )),
            secondaryLeft: ("Guest", guest),
            secondaryRight: ("Door PIN", PassFieldBag.value(fields, ["door_pin"], fallback: "4 8 2 9 #")),
            tertiaryLeft: ("", ""),
            tertiaryRight: ("", ""),
            footerLeft: nil,
            footerRight: nil,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: ""),
            nfcTitle: "Hold Near Door Lock to Unlock",
            nfcSubtitle: "Apple VAS NFC • Express Mode"
        )
    }


    static func zoomcar(_ fields: [String: String]) -> KeylessFaceModel {
        return KeylessFaceModel(
            title: PassFieldBag.value(fields, ["vehicle"], fallback: "Hyundai Creta SX (O)"),
            subtitleBadge: PassFieldBag.value(fields, ["vehicle_type"], fallback: "Self-Drive"),
            status: PassFieldBag.value(fields, ["key_status"], fallback: "READY TO UNLOCK"),
            primaryLeft: ("Registration", PassFieldBag.value(fields, ["plate", "registration"], fallback: "KA-05-MQ-4421")),
            primaryRight: ("Key Status", PassFieldBag.value(fields, ["key_status"], fallback: "READY")),
            secondaryLeft: ("Pickup", PassFieldBag.value(fields, ["pickup"], fallback: "Sat, 28 Oct • 09:00")),
            secondaryRight: ("Drop Off", PassFieldBag.value(fields, ["drop_off"], fallback: "Sun, 29 Oct • 21:00")),
            tertiaryLeft: ("Backup PIN", PassFieldBag.value(fields, ["door_pin"], fallback: "7 9 2 4 #")),
            tertiaryRight: ("", ""),
            footerLeft: nil,
            footerRight: nil,
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: ""),
            nfcTitle: "Hold iPhone Near Windshield Reader",
            nfcSubtitle: "Express Mode · Backup PIN available"
        )
    }

}

struct UPIFaceModel {
    var name: String
    var vpa: String
    var bank: String
    var account: String
    var txnLimit: String
    var autopay: String
    var ifsc: String
    var status: String
    var amount: String
    var note: String
}

extension UPIFaceModel {
    static func from(_ fields: [String: String]) -> UPIFaceModel {
        // Face shows holder + VPA + bank + status. Limits/IFSC/account/amount → flip.
        UPIFaceModel(
            name: PassFieldBag.value(fields, ["name"], fallback: "Rohit Kumar"),
            vpa: PassFieldBag.value(fields, ["vpa", "qr_data"], fallback: "rohitkumar@icici"),
            bank: PassFieldBag.value(fields, ["bank"], fallback: "ICICI Bank"),
            account: "",
            txnLimit: "",
            autopay: "",
            ifsc: "",
            status: PassFieldBag.value(fields, ["status"], fallback: "ACTIVE VPA"),
            amount: "",
            note: ""
        )
    }

}

struct MetroFaceModel {
    var origin: String
    var originPlatform: String
    var destination: String
    var exits: String
    var issuedAt: String
    var validTill: String
    var booking: String
    var ticketType: String
    var line: String
    var routeMeta: String
    var passenger: String
    var time: String
    var arr: String
}

extension MetroFaceModel {
    static func namma(_ fields: [String: String]) -> MetroFaceModel {
        return MetroFaceModel(
            origin: PassFieldBag.value(fields, ["origin"], fallback: "Indiranagar"),
            originPlatform: "",
            destination: PassFieldBag.value(fields, ["destination"], fallback: "MG Road"),
            exits: "",
            issuedAt: "",
            validTill: PassFieldBag.value(fields, ["valid_till", "valid"], fallback: "20:42 (120m)"),
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "BMRCL-892401"),
            ticketType: PassFieldBag.value(fields, ["ticket_type"], fallback: "QR SINGLE JOURNEY"),
            line: PassFieldBag.value(fields, ["line"], fallback: "PURPLE LINE"),
            routeMeta: "Metro",
            passenger: "",
            time: "",
            arr: ""
        )
    }

}

struct MembershipFaceModel {
    var name: String
    var center: String
    var plan: String
    var membership: String
    var validThru: String
    var checkins: String
    var memberId: String
    var status: String
    var booking: String
}

extension MembershipFaceModel {
    static func cult(_ fields: [String: String]) -> MembershipFaceModel {
        MembershipFaceModel(
            name: PassFieldBag.value(fields, ["name"], fallback: "Rohit Kumar"),
            center: PassFieldBag.value(fields, ["center"], fallback: "Cult Indiranagar"),
            plan: PassFieldBag.value(fields, ["plan"], fallback: "ELITE"),
            membership: PassFieldBag.value(fields, ["membership"], fallback: "Cult Pass"),
            validThru: PassFieldBag.value(fields, ["valid_thru"], fallback: "31 Mar 2027"),
            checkins: PassFieldBag.value(fields, ["checkins"], fallback: "142 check-ins"),
            memberId: PassFieldBag.value(fields, ["member_id"], fallback: "CULT-884201"),
            status: PassFieldBag.value(fields, ["status"], fallback: "ACTIVE"),
            booking: PassFieldBag.value(fields, ["qr_data", "member_id"], fallback: "CULT-884201")
        )
    }

    static func golds(_ fields: [String: String]) -> MembershipFaceModel {
        MembershipFaceModel(
            name: PassFieldBag.value(fields, ["name"], fallback: "Rohit Kumar"),
            center: PassFieldBag.value(fields, ["center"], fallback: "Gold's Gym Koramangala"),
            plan: PassFieldBag.value(fields, ["plan"], fallback: "Platinum"),
            membership: PassFieldBag.value(fields, ["membership"], fallback: "All Clubs Access"),
            validThru: PassFieldBag.value(fields, ["valid_thru"], fallback: "31 Dec 2026"),
            checkins: PassFieldBag.value(fields, ["checkins"], fallback: ""),
            memberId: PassFieldBag.value(fields, ["member_id"], fallback: "GG-552190"),
            status: PassFieldBag.value(fields, ["status"], fallback: "ACTIVE"),
            booking: PassFieldBag.value(fields, ["qr_data", "member_id"], fallback: "GG-552190")
        )
    }
}

struct RideFaceModel {
    var service: String
    var status: String
    var pickup: String
    var drop: String
    var vehicle: String
    var driver: String
    var pin: String
    var eta: String
    var booking: String
}

extension RideFaceModel {
    static func ride(_ fields: [String: String], fallbackService: String) -> RideFaceModel {
        RideFaceModel(
            service: PassFieldBag.value(fields, ["service", "vehicle_type"], fallback: fallbackService),
            status: PassFieldBag.value(fields, ["status"], fallback: "CONFIRMED"),
            pickup: PassFieldBag.value(fields, ["pickup"], fallback: "Terminal 2 Departures"),
            drop: PassFieldBag.value(fields, ["drop_off", "destination"], fallback: "Indiranagar 100ft Rd"),
            vehicle: PassFieldBag.value(fields, ["vehicle", "plate"], fallback: "KA-01-AB-1234"),
            driver: PassFieldBag.value(fields, ["driver", "guest", "passenger"], fallback: "Driver assigned"),
            pin: PassFieldBag.value(fields, ["ride_pin", "door_pin"], fallback: "4829"),
            eta: PassFieldBag.value(fields, ["eta", "time"], fallback: "12 min"),
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data"], fallback: "RIDE-10293")
        )
    }
}

struct RetailFaceModel {
    var store: String
    var offer: String
    var member: String
    var points: String
    var valid: String
    var code: String
    var tier: String
    var booking: String
}

extension RetailFaceModel {
    static func loyalty(_ fields: [String: String], fallbackStore: String) -> RetailFaceModel {
        RetailFaceModel(
            store: PassFieldBag.value(fields, ["store", "restaurant", "venue"], fallback: fallbackStore),
            offer: PassFieldBag.value(fields, ["offer", "offer_code", "discount"], fallback: "Member rewards"),
            member: PassFieldBag.value(fields, ["guest", "name"], fallback: "Rohit Kumar"),
            points: PassFieldBag.value(fields, ["points", "cashless_balance"], fallback: ""),
            valid: PassFieldBag.value(fields, ["valid_thru", "valid_till", "time"], fallback: ""),
            code: PassFieldBag.value(fields, ["offer_code", "booking_id"], fallback: ""),
            tier: PassFieldBag.value(fields, ["tier", "membership_status"], fallback: "Member"),
            booking: PassFieldBag.value(fields, ["booking_id", "qr_data", "member_id"], fallback: "NEU-1001")
        )
    }
}
