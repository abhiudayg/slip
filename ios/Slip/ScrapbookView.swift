import MapKit
import SwiftUI

/// Year-in-review / scrapbook from vault history (active + expired).
struct ScrapbookView: View {
    @EnvironmentObject private var vault: PassVaultStore
    @Environment(\.dismiss) private var dismiss

    private var year: Int { Calendar.current.component(.year, from: Date()) }

    private var entries: ScrapbookEntry {
        ScrapbookStats.build(from: vault.records, decrypt: { try? vault.decrypt($0) }, year: year)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        statsRow
                        if !entries.airports.isEmpty {
                            mapSection
                        }
                        moviesSection
                        concertsSection
                        travelSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scrapbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your \(year) in Slip")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(SlipTheme.ink)
            Text("Archived and active passes — movies, flights, and nights out, woven into one scrapbook.")
                .font(.subheadline)
                .foregroundStyle(SlipTheme.muted)
        }
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard("\(entries.totalPasses)", "Passes")
            statCard("\(entries.movies.count)", "Movies")
            statCard("\(entries.airports.count)", "Airports")
            statCard("\(entries.concerts.count)", "Events")
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(SlipTheme.ink)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SlipTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(SlipTheme.cardHigh))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Airports this year")
                .font(.headline)
                .foregroundStyle(SlipTheme.ink)
            Text(entries.airports.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(SlipTheme.muted)
            // Lightweight map of geocoded coords when present on payloads.
            if !entries.mapPins.isEmpty {
                Map {
                    ForEach(Array(entries.mapPins.enumerated()), id: \.offset) { _, pin in
                        Marker(pin.title, coordinate: pin.coordinate)
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var moviesSection: some View {
        scrapGrid(title: "Movies & screens", items: entries.movies, tint: SlipTheme.accent)
    }

    private var concertsSection: some View {
        scrapGrid(title: "Concerts & festivals", items: entries.concerts, tint: SlipTheme.magenta)
    }

    private var travelSection: some View {
        scrapGrid(title: "Trips & stays", items: entries.trips, tint: SlipTheme.indigo)
    }

    private func scrapGrid(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(SlipTheme.ink)
            if items.isEmpty {
                Text("Nothing archived yet — keep adding tickets.")
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(tint.opacity(0.14))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(tint.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

struct ScrapbookEntry {
    var totalPasses: Int
    var movies: [String]
    var concerts: [String]
    var trips: [String]
    var airports: [String]
    var mapPins: [(title: String, coordinate: CLLocationCoordinate2D)]
}

enum ScrapbookStats {
    static func build(
        from records: [PassVaultRecord],
        decrypt: (PassVaultRecord) -> PassVaultPayload?,
        year: Int
    ) -> ScrapbookEntry {
        var movies: [String] = []
        var concerts: [String] = []
        var trips: [String] = []
        var airports = Set<String>()
        var pins: [(String, CLLocationCoordinate2D)] = []
        var total = 0

        for record in records {
            let createdYear = Calendar.current.component(.year, from: record.createdAt)
            let expiredYear = record.expiresAt.map { Calendar.current.component(.year, from: $0) }
            guard createdYear == year || expiredYear == year else { continue }
            total += 1
            guard let payload = decrypt(record) else { continue }
            let fields = payload.fields
            switch payload.templateId {
            case "bookmyshow":
                if let e = nonEmpty(fields["event"]) { movies.append(e) }
            case "district":
                if let e = nonEmpty(fields["event"]) { concerts.append(e) }
            case "indigo", "makemytrip", "cleartrip", "yatra":
                if let o = nonEmpty(fields["origin"]) { airports.insert(short(o)) }
                if let d = nonEmpty(fields["destination"]) { airports.insert(short(d)) }
                let route = [fields["origin"], fields["destination"]].compactMap(nonEmpty).joined(separator: " → ")
                if !route.isEmpty { trips.append(route) }
            case "irctc", "redbus", "namma-metro":
                let route = [fields["origin"], fields["destination"]].compactMap(nonEmpty).joined(separator: " → ")
                if !route.isEmpty { trips.append(route) }
            case "airbnb":
                if let p = nonEmpty(fields["property"]) { trips.append(p) }
            case "easydiner", "zomato-dineout", "swiggy-dineout":
                if let r = nonEmpty(fields["restaurant"]) { concerts.append(r) }
            default:
                break
            }
            if let lat = BrandFields.parseCoordinate(fields["latitude"]),
               let lon = BrandFields.parseCoordinate(fields["longitude"]) {
                pins.append((record.displayName, CLLocationCoordinate2D(latitude: lat, longitude: lon)))
            }
        }

        return ScrapbookEntry(
            totalPasses: total,
            movies: uniquePreserve(movies),
            concerts: uniquePreserve(concerts),
            trips: uniquePreserve(trips),
            airports: airports.sorted(),
            mapPins: pins
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func short(_ text: String) -> String {
        if let paren = text.split(separator: "(").last?.split(separator: ")").first, paren.count <= 5 {
            return String(paren).uppercased()
        }
        return String(text.prefix(12))
    }

    private static func uniquePreserve(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for item in items {
            let key = item.lowercased()
            if seen.insert(key).inserted { out.append(item) }
        }
        return out
    }
}
