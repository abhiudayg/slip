import CoreLocation
import MapKit
import Foundation
import UserNotifications

/// Registers circular geofences for pass venues and notifies on entry.
/// Resolves coords from: explicit lat/lon → `lat,lon` location string → geocoded place name → metro stations.
@MainActor
final class PassGeofenceManager: NSObject, ObservableObject {
    static let shared = PassGeofenceManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var monitoredRegionCount: Int = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastRegisteredLabel: String?

    private let manager = CLLocationManager()
    private var stations: [MetroStation] = []
    private var registerTask: Task<Void, Never>?

    struct MetroStation: Hashable {
        var id: String
        var name: String
        var latitude: Double
        var longitude: Double
    }

    struct GeoPoint: Hashable {
        var id: String
        var name: String
        var latitude: Double
        var longitude: Double
    }

    private override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        stations = Self.loadBundledStations()
        monitoredRegionCount = manager.monitoredRegions.count
    }

    var shortLabel: String {
        switch authorizationStatus {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not asked"
        @unknown default: return "Unknown"
        }
    }

    var isGranted: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    var canMonitorRegions: Bool {
        authorizationStatus == .authorizedAlways && CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }

    func requestAccess() {
        lastError = nil
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        // Always is required for reliable background geofence wakeups.
        manager.requestAlwaysAuthorization()
        authorizationStatus = manager.authorizationStatus
    }

    /// Registers up to 2 regions for a pass (explicit coords, geocoded location, or metro stations).
    func register(for classification: ClassificationResult, radiusMeters: CLLocationDistance = 350) {
        registerTask?.cancel()
        registerTask = Task { [weak self] in
            await self?.registerAsync(for: classification, radiusMeters: radiusMeters)
        }
    }

    func register(fields: [String: String], templateId: String, displayName: String, stationIds: [String] = [], radiusMeters: CLLocationDistance = 350) {
        let classification = ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: 1,
            fields: fields,
            stationIds: stationIds,
            relevantDateISO8601: fields["date"] ?? fields["dep"],
            rationale: "geofence",
            needsManualBrandPick: false,
            extracted: ExtractedTicket(
                qrPayload: fields["qr_data"],
                barcodeSymbology: nil,
                recognizedText: "",
                tokens: [],
                createdAt: Date()
            ),
            createdAt: Date()
        )
        register(for: classification, radiusMeters: radiusMeters)
    }

    private func registerAsync(for classification: ClassificationResult, radiusMeters: CLLocationDistance) async {
        guard canMonitorRegions else {
            if authorizationStatus == .authorizedWhenInUse {
                lastError = "Geofence wakeups need Always location access."
                manager.requestAlwaysAuthorization()
            }
            return
        }

        let candidates = await resolvePoints(for: classification)
        clearSlipRegions()

        for point in candidates.prefix(2) {
            let center = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            let region = CLCircularRegion(
                center: center,
                radius: radiusMeters,
                identifier: "slip.\(classification.templateId).\(point.id)"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
        monitoredRegionCount = manager.monitoredRegions.count
        lastRegisteredLabel = candidates.first?.name
        if candidates.isEmpty {
            lastError = "Add a Location (or lat/lon) on this pass so geofence can arm."
        } else {
            lastError = nil
        }
    }

    func clearAll() {
        registerTask?.cancel()
        clearSlipRegions()
        lastRegisteredLabel = nil
    }

    private func clearSlipRegions() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix("slip.") {
            manager.stopMonitoring(for: region)
        }
        monitoredRegionCount = manager.monitoredRegions.count
    }

    /// Prefer explicit coordinates, then geocode `location`, then metro station catalog matches.
    private func resolvePoints(for classification: ClassificationResult) async -> [GeoPoint] {
        var points: [GeoPoint] = []
        let fields = classification.fields

        if let lat = BrandFields.parseCoordinate(fields["latitude"]),
           let lon = BrandFields.parseCoordinate(fields["longitude"]) {
            let name = fields["location"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            points.append(
                GeoPoint(
                    id: "coords",
                    name: (name?.isEmpty == false) ? name! : classification.displayName,
                    latitude: lat,
                    longitude: lon
                )
            )
        } else if let pair = BrandFields.parseLatLonPair(fields["location"]) {
            points.append(
                GeoPoint(
                    id: "coords",
                    name: classification.displayName,
                    latitude: pair.0,
                    longitude: pair.1
                )
            )
        }

        if points.isEmpty, let query = BrandFields.geocodeQuery(from: fields) {
            if let geocoded = await geocode(query) {
                points.append(geocoded)
                // Persist resolved coords back? Caller owns fields — skip mutation here.
            }
        }

        let metro = matchedStations(for: classification).map {
            GeoPoint(id: $0.id, name: $0.name, latitude: $0.latitude, longitude: $0.longitude)
        }
        for station in metro where !points.contains(where: { abs($0.latitude - station.latitude) < 0.0001 && abs($0.longitude - station.longitude) < 0.0001 }) {
            points.append(station)
        }
        return points
    }

    private func geocode(_ query: String) async -> GeoPoint? {
        do {
            guard let request = MKGeocodingRequest(addressString: query) else { return nil }
            let items = try await request.mapItems
            guard let item = items.first else { return nil }
            let loc = item.location
            let label = [item.name, item.address?.shortAddress, item.address?.fullAddress]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? query
            let id = "geo.\(abs(query.hashValue))"
            return GeoPoint(id: id, name: label, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        } catch {
            lastError = "Couldn’t geocode “\(query)”."
            return nil
        }
    }


    private func matchedStations(for classification: ClassificationResult) -> [MetroStation] {
        if !classification.stationIds.isEmpty {
            let wanted = Set(classification.stationIds.map { $0.lowercased() })
            let byId = stations.filter { wanted.contains($0.id.lowercased()) }
            if !byId.isEmpty { return byId }
        }

        let hay = [
            classification.fields["location"],
            classification.fields["origin"],
            classification.fields["destination"],
            classification.fields["venue"],
            classification.fields["property"],
            classification.fields["address"],
            classification.fields["pickup"],
            classification.fields["restaurant"],
            classification.fields["from"],
            classification.fields["to"],
            classification.displayName
        ]
        .compactMap { $0?.lowercased() }
        .joined(separator: " ")

        guard !hay.isEmpty else { return [] }

        return stations.filter { station in
            hay.contains(station.name.lowercased())
                || hay.contains(station.id.lowercased())
                || hay.contains(station.name.lowercased().replacingOccurrences(of: " ", with: ""))
        }
    }

    private static func loadBundledStations() -> [MetroStation] {
        guard let url = Bundle.main.url(forResource: "namma-metro", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["stations"] as? [[String: Any]] else {
            return []
        }
        return list.compactMap { row in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lon = row["longitude"] as? Double else { return nil }
            return MetroStation(id: id, name: name, latitude: lat, longitude: lon)
        }
    }

    private func postArrivalNotification(stationName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Slip · Near \(stationName)"
        content.body = "Your pass is ready — double-click Side Button for Wallet."
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "slip.geo.\(stationName).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

extension PassGeofenceManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            let pretty = self.stations.first(where: { region.identifier.hasSuffix($0.id) })?.name
                ?? self.lastRegisteredLabel
                ?? region.identifier.split(separator: ".").last.map(String.init)
                ?? "venue"
            self.postArrivalNotification(stationName: pretty)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
        }
    }
}

enum PassLocationBuilder {
    static func from(fields: [String: String]) -> [PassLocation] {
        if let lat = BrandFields.parseCoordinate(fields["latitude"]),
           let lon = BrandFields.parseCoordinate(fields["longitude"]) {
            let text = fields["location"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            return [PassLocation(latitude: lat, longitude: lon, relevantText: (text?.isEmpty == false) ? text : nil)]
        }
        if let pair = BrandFields.parseLatLonPair(fields["location"]) {
            let text = fields["location"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            return [PassLocation(latitude: pair.0, longitude: pair.1, relevantText: text)]
        }
        return []
    }
}
