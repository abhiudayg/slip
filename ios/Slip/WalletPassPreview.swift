import SwiftUI

/// Stitch-faithful Apple Wallet pass cards (stitch_indian_wallet_pass_studio).
struct WalletPassPreview: View {
    let brandId: String
    let displayName: String
    @Binding var fields: [String: String]
    var accentRGB: String? = nil
    /// When true, primary values on brand cards are inline-editable.
    var editable: Bool = true

    var body: some View {
        PassDeviceBezel {
            PassFlipContainer(
                brandTitle: displayName,
                backRows: PassBackContent.rows(brandId: brandId, fields: fields)
            ) {
                frontFace
            }
        }
        // Force card rebuild when any field value changes (SwiftUI can miss deep dict diffs).
        .id(fields.keys.sorted().map { "\($0)=\(fields[$0] ?? "")" }.joined(separator: "|"))
    }

    @ViewBuilder
    private var frontFace: some View {
        switch brandId {
        case "airbnb": AirbnbRoomKeyCard(fields: $fields, editable: editable)
        case "bookmyshow": BookMyShowTicketCard(fields: fields)
        case "district": DistrictFestivalCard(fields: fields)
        case "irctc": IRCTCRailCard(fields: fields)
        case "indigo": IndigoBoardingCard(fields: fields)
        case "namma-metro": NammaMetroCard(fields: fields)
        case "redbus": RedBusCard(fields: fields)
        case "zoomcar": ZoomcarKeylessCard(fields: fields)
        case "upi": UPIPayPassCard(fields: fields)
        case "easydiner": EazyDinerPrimeCard(fields: fields)
        case "zomato-dineout": ZomatoDiningCard(fields: fields)
        case "swiggy-dineout": SwiggyDineoutCard(fields: fields)
        case "cult": CultAccessCard(fields: fields)
        case "golds-gym": GoldsGymAccessCard(fields: fields)
        case "uber": RideHailingCard(brand: "uber", fields: fields, palette: PassPalettes.uber)
        case "ola": RideHailingCard(brand: "ola", fields: fields, palette: PassPalettes.ola)
        case "makemytrip": TravelOTACard(brandTitle: "MakeMyTrip", fields: fields, palette: PassPalettes.mmt)
        case "cleartrip": TravelOTACard(brandTitle: "Cleartrip", fields: fields, palette: PassPalettes.mmt)
        case "yatra": TravelOTACard(brandTitle: "Yatra", fields: fields, palette: PassPalettes.mmt)
        case "uts": TravelOTACard(brandTitle: "UTS", fields: fields, palette: PassPalettes.irctc)
        case "chalo": TravelOTACard(brandTitle: "Chalo", fields: fields, palette: PassPalettes.redbus)
        case "tata-neu": RetailLoyaltyCard(brandTitle: "Tata Neu", fields: fields, palette: PassPalettes.neu, systemImage: "n.circle.fill")
        case "reliance-smart": RetailLoyaltyCard(brandTitle: "Reliance Smart", fields: fields, palette: PassPalettes.swiggy, systemImage: "cart.fill")
        case "shoppers-stop": RetailLoyaltyCard(brandTitle: "Shoppers Stop", fields: fields, palette: PassPalettes.district, systemImage: "bag.fill")
        case "bigbasket": RetailLoyaltyCard(brandTitle: "BigBasket", fields: fields, palette: PassPalettes.zoomcar, systemImage: "leaf.fill")
        default:
            GenericStitchCard(brandId: brandId, displayName: displayName, fields: fields, accentRGB: accentRGB)
        }
    }

    // Compatibility shims for any call sites still using WalletPassPreview.* helpers.
    static func value(_ fields: [String: String], _ keys: [String], fallback: String = "—") -> String {
        PassFieldBag.value(fields, keys, fallback: fallback)
    }

    static func join(_ parts: [String], separator: String = "\n") -> String {
        PassFieldBag.join(parts, separator: separator)
    }

    static func pair(_ primary: String, _ secondary: String, separator: String = " · ") -> String {
        PassFieldBag.pair(primary, secondary, separator: separator)
    }

    static func abbreviate(_ text: String) -> String {
        PassFieldBag.abbreviate(text)
    }
}
