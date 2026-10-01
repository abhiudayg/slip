import SwiftUI
import UIKit

struct PassPalette {
    var top: Color
    var mid: Color
    var bottom: Color
    var accent: Color
    var accentSoft: Color
    var border: Color
    var glow: Color
}

enum PassPalettes {
    static let airbnb = PassPalette(
        top: Color(red: 0.13, green: 0.07, blue: 0.09),
        mid: Color(red: 0.10, green: 0.055, blue: 0.07),
        bottom: Color(red: 0.07, green: 0.035, blue: 0.047),
        accent: Color(red: 1.0, green: 0.22, blue: 0.36),
        accentSoft: Color(red: 1.0, green: 0.59, blue: 0.67),
        border: Color(red: 1.0, green: 0.22, blue: 0.36).opacity(0.28),
        glow: Color(red: 0.55, green: 0.05, blue: 0.15).opacity(0.55)
    )
    static let bms = PassPalette(
        top: Color(red: 0.12, green: 0.04, blue: 0.05),
        mid: Color(red: 0.09, green: 0.03, blue: 0.035),
        bottom: Color(red: 0.05, green: 0.01, blue: 0.02),
        accent: Color(red: 0.86, green: 0.21, blue: 0.35),
        accentSoft: Color(red: 1.0, green: 0.55, blue: 0.62),
        border: Color(red: 0.86, green: 0.21, blue: 0.35).opacity(0.28),
        glow: Color(red: 0.45, green: 0.02, blue: 0.08).opacity(0.55)
    )
    static let irctc = PassPalette(
        top: Color(red: 0.09, green: 0.14, blue: 0.23),
        mid: Color(red: 0.07, green: 0.10, blue: 0.17),
        bottom: Color(red: 0.04, green: 0.06, blue: 0.11),
        accent: Color(red: 0.96, green: 0.70, blue: 0.20),
        accentSoft: Color(red: 0.98, green: 0.82, blue: 0.45),
        border: Color(red: 0.96, green: 0.70, blue: 0.20).opacity(0.28),
        glow: Color(red: 0.05, green: 0.15, blue: 0.40).opacity(0.55)
    )
    static let indigo = PassPalette(
        top: Color(hex: 0x0E2747),
        mid: Color(hex: 0x091B33),
        bottom: Color(hex: 0x071324),
        accent: Color(hex: 0x60A5FA),
        accentSoft: Color(hex: 0x93C5FD),
        border: Color.white.opacity(0.12),
        glow: Color(hex: 0x1E3A8A).opacity(0.55)
    )
    static let metro = PassPalette(
        top: Color(red: 0.12, green: 0.07, blue: 0.22),
        mid: Color(red: 0.08, green: 0.05, blue: 0.16),
        bottom: Color(red: 0.05, green: 0.03, blue: 0.10),
        accent: Color(red: 0.55, green: 0.30, blue: 0.95),
        accentSoft: Color(red: 0.75, green: 0.60, blue: 1.0),
        border: Color(red: 0.55, green: 0.30, blue: 0.95).opacity(0.3),
        glow: Color(red: 0.25, green: 0.08, blue: 0.45).opacity(0.5)
    )
    static let redbus = PassPalette(
        top: Color(red: 0.18, green: 0.05, blue: 0.05),
        mid: Color(red: 0.12, green: 0.04, blue: 0.04),
        bottom: Color(red: 0.07, green: 0.02, blue: 0.02),
        accent: Color(red: 0.90, green: 0.18, blue: 0.20),
        accentSoft: Color(red: 1.0, green: 0.55, blue: 0.55),
        border: Color(red: 0.90, green: 0.18, blue: 0.20).opacity(0.28),
        glow: Color(red: 0.40, green: 0.02, blue: 0.05).opacity(0.5)
    )
    static let zoomcar = PassPalette(
        top: Color(red: 0.09, green: 0.14, blue: 0.06),
        mid: Color(red: 0.06, green: 0.09, blue: 0.04),
        bottom: Color(red: 0.03, green: 0.05, blue: 0.02),
        accent: Color(red: 0.55, green: 0.90, blue: 0.25),
        accentSoft: Color(red: 0.70, green: 0.95, blue: 0.45),
        border: Color(red: 0.55, green: 0.90, blue: 0.25).opacity(0.28),
        glow: Color(red: 0.15, green: 0.35, blue: 0.05).opacity(0.5)
    )
    static let upi = PassPalette(
        top: Color(red: 0.05, green: 0.10, blue: 0.18),
        mid: Color(red: 0.04, green: 0.08, blue: 0.14),
        bottom: Color(red: 0.02, green: 0.05, blue: 0.09),
        accent: Color(red: 0.25, green: 0.55, blue: 0.95),
        accentSoft: Color(red: 0.55, green: 0.75, blue: 1.0),
        border: Color(red: 0.25, green: 0.55, blue: 0.95).opacity(0.28),
        glow: Color(red: 0.05, green: 0.2, blue: 0.45).opacity(0.5)
    )
    static let zomato = PassPalette(
        top: Color(red: 0.165, green: 0.055, blue: 0.08),
        mid: Color(red: 0.11, green: 0.03, blue: 0.05),
        bottom: Color(red: 0.06, green: 0.012, blue: 0.024),
        accent: Color(red: 0.89, green: 0.22, blue: 0.27),
        accentSoft: Color(red: 1.0, green: 0.60, blue: 0.65),
        border: Color(red: 0.89, green: 0.22, blue: 0.27).opacity(0.28),
        glow: Color(red: 0.40, green: 0.05, blue: 0.08).opacity(0.5)
    )
    static let easydiner = PassPalette(
        top: Color(red: 0.14, green: 0.10, blue: 0.05),
        mid: Color(red: 0.10, green: 0.07, blue: 0.03),
        bottom: Color(red: 0.06, green: 0.04, blue: 0.02),
        accent: Color(red: 0.90, green: 0.65, blue: 0.22),
        accentSoft: Color(red: 0.98, green: 0.82, blue: 0.45),
        border: Color(red: 0.90, green: 0.65, blue: 0.22).opacity(0.28),
        glow: Color(red: 0.35, green: 0.22, blue: 0.05).opacity(0.5)
    )
    static let swiggy = PassPalette(
        top: Color(red: 0.16, green: 0.09, blue: 0.04),
        mid: Color(red: 0.11, green: 0.06, blue: 0.03),
        bottom: Color(red: 0.07, green: 0.03, blue: 0.015),
        accent: Color(red: 0.99, green: 0.50, blue: 0.10),
        accentSoft: Color(red: 1.0, green: 0.70, blue: 0.40),
        border: Color(red: 0.99, green: 0.50, blue: 0.10).opacity(0.28),
        glow: Color(red: 0.40, green: 0.18, blue: 0.02).opacity(0.5)
    )
    static let district = PassPalette(
        top: Color(red: 0.10, green: 0.06, blue: 0.18),
        mid: Color(red: 0.07, green: 0.04, blue: 0.13),
        bottom: Color(red: 0.04, green: 0.02, blue: 0.08),
        accent: Color(red: 0.49, green: 0.23, blue: 0.93),
        accentSoft: Color(red: 0.72, green: 0.58, blue: 1.0),
        border: Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.3),
        glow: Color(red: 0.22, green: 0.08, blue: 0.45).opacity(0.5)
    )

    static let genericDark = PassPalette(
        top: Color(red: 0.10, green: 0.10, blue: 0.14),
        mid: Color(red: 0.07, green: 0.07, blue: 0.10),
        bottom: Color(red: 0.04, green: 0.04, blue: 0.06),
        accent: Color.cyan,
        accentSoft: Color.cyan.opacity(0.85),
        border: Color.white.opacity(0.2),
        glow: Color.black.opacity(0.35)
    )
    static let cult = PassPalette(
        top: Color(red: 0.12, green: 0.05, blue: 0.07),
        mid: Color(red: 0.09, green: 0.04, blue: 0.05),
        bottom: Color(red: 0.05, green: 0.02, blue: 0.03),
        accent: Color(red: 0.90, green: 0.18, blue: 0.28),
        accentSoft: Color(red: 1.0, green: 0.55, blue: 0.62),
        border: Color(red: 0.90, green: 0.18, blue: 0.28).opacity(0.3),
        glow: Color(red: 0.55, green: 0.05, blue: 0.12).opacity(0.5)
    )
    static let golds = PassPalette(
        top: Color(red: 0.10, green: 0.09, blue: 0.05),
        mid: Color(red: 0.07, green: 0.06, blue: 0.03),
        bottom: Color(red: 0.04, green: 0.03, blue: 0.02),
        accent: Color(red: 0.85, green: 0.68, blue: 0.22),
        accentSoft: Color(red: 0.95, green: 0.82, blue: 0.45),
        border: Color(red: 0.85, green: 0.68, blue: 0.22).opacity(0.3),
        glow: Color(red: 0.45, green: 0.35, blue: 0.05).opacity(0.45)
    )
    static let uber = PassPalette(
        top: Color(red: 0.08, green: 0.08, blue: 0.09),
        mid: Color(red: 0.05, green: 0.05, blue: 0.06),
        bottom: Color(red: 0.02, green: 0.02, blue: 0.03),
        accent: Color.white,
        accentSoft: Color.white.opacity(0.75),
        border: Color.white.opacity(0.22),
        glow: Color.black.opacity(0.5)
    )
    static let ola = PassPalette(
        top: Color(red: 0.05, green: 0.10, blue: 0.07),
        mid: Color(red: 0.03, green: 0.07, blue: 0.05),
        bottom: Color(red: 0.02, green: 0.04, blue: 0.03),
        accent: Color(red: 0.20, green: 0.78, blue: 0.35),
        accentSoft: Color(red: 0.55, green: 0.92, blue: 0.65),
        border: Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.3),
        glow: Color(red: 0.05, green: 0.35, blue: 0.12).opacity(0.45)
    )
    static let neu = PassPalette(
        top: Color(red: 0.08, green: 0.06, blue: 0.12),
        mid: Color(red: 0.05, green: 0.04, blue: 0.09),
        bottom: Color(red: 0.03, green: 0.02, blue: 0.06),
        accent: Color(red: 0.55, green: 0.35, blue: 0.95),
        accentSoft: Color(red: 0.75, green: 0.62, blue: 1.0),
        border: Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.3),
        glow: Color(red: 0.25, green: 0.1, blue: 0.45).opacity(0.45)
    )
    static let mmt = PassPalette(
        top: Color(red: 0.08, green: 0.10, blue: 0.16),
        mid: Color(red: 0.05, green: 0.07, blue: 0.12),
        bottom: Color(red: 0.03, green: 0.04, blue: 0.08),
        accent: Color(red: 0.25, green: 0.45, blue: 0.95),
        accentSoft: Color(red: 0.55, green: 0.7, blue: 1.0),
        border: Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.3),
        glow: Color(red: 0.1, green: 0.2, blue: 0.45).opacity(0.45)
    )

}


extension PassPalettes {
    /// Dynamic palette for unknown brands — samples the ticket screenshot / PDF thumbnail.
    static func fromTicketImage(_ image: UIImage?) -> PassPalette {
        let swatch = image.flatMap { TicketColorExtractor.extract(from: $0) } ?? TicketColorExtractor.cachedSwatch()
        guard let swatch else {
            return genericDark
        }
        let top = Color(red: swatch.dominant.r * 0.35, green: swatch.dominant.g * 0.35, blue: swatch.dominant.b * 0.35)
        let mid = Color(red: swatch.secondary.r * 0.28, green: swatch.secondary.g * 0.28, blue: swatch.secondary.b * 0.28)
        let bottom = Color(red: swatch.secondary.r * 0.16, green: swatch.secondary.g * 0.16, blue: swatch.secondary.b * 0.16)
        let accent = Color(red: swatch.accent.r, green: swatch.accent.g, blue: swatch.accent.b)
        return PassPalette(
            top: top,
            mid: mid,
            bottom: bottom,
            accent: accent,
            accentSoft: accent.opacity(0.75),
            border: accent.opacity(0.3),
            glow: accent.opacity(0.45)
        )
    }

    static func resolved(templateId: String, ticketImage: UIImage? = nil) -> PassPalette {
        switch templateId {
        case "bookmyshow": return bms
        case "district": return district
        case "irctc": return irctc
        case "indigo": return indigo
        case "namma-metro": return metro
        case "redbus": return redbus
        case "zoomcar": return zoomcar
        case "upi": return upi
        case "airbnb": return airbnb
        case "easydiner", "zomato-dineout", "swiggy-dineout": return easydiner
        case "uber": return uber
        case "ola": return ola
        case "makemytrip", "cleartrip", "yatra": return mmt
        default:
            return fromTicketImage(ticketImage)
        }
    }
}
