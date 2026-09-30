import CoreLocation
import Foundation
import UserNotifications

/// Registers circular geofences for pass venues (metro stations) and notifies on entry.
@MainActor
final class PassGeofenceManager: NSObject, ObservableObject {
    static let shared = PassGeofenceManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var monitoredRegionCount: Int = 0
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()
    private var stations: [MetroStation] = []

    struct MetroStation: Hashable {
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

    /// Registers up to 2 regions (origin / destination stations) for a pass.
    func register(for classification: ClassificationResult, radiusMeters: CLLocationDistance = 350) {
        guard canMonitorRegions else {
            if authorizationStatus == .authorizedWhenInUse {
                lastError = "Geofence wakeups need Always location access."
                manager.requestAlwaysAuthorization()
            }
            return
        }

        let candidates = matchedStations(for: classification)
        // Clear previous Slip regions to stay under iOS ~20 region limit.
        for region in manager.monitoredRegions {
            if region.identifier.hasPrefix("slip.") {
                manager.stopMonitoring(for: region)
            }
        }

        for station in candidates.prefix(2) {
            let center = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            let region = CLCircularRegion(
                center: center,
                radius: radiusMeters,
                identifier: "slip.\(classification.templateId).\(station.id)"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
        monitoredRegionCount = manager.monitoredRegions.count
    }

    func clearAll() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix("slip.") {
            manager.stopMonitoring(for: region)
        }
        monitoredRegionCount = manager.monitoredRegions.count
    }

    private func matchedStations(for classification: ClassificationResult) -> [MetroStation] {
        if !classification.stationIds.isEmpty {
            let wanted = Set(classification.stationIds.map { $0.lowercased() })
            let byId = stations.filter { wanted.contains($0.id.lowercased()) }
            if !byId.isEmpty { return byId }
        }

        let hay = [
            classification.fields["origin"],
            classification.fields["destination"],
            classification.fields["venue"],
            classification.fields["property"],
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
        let name = region.identifier.split(separator: ".").last.map(String.init) ?? "venue"
        Task { @MainActor in
            let pretty = self.stations.first(where: { region.identifier.hasSuffix($0.id) })?.name ?? name
            self.postArrivalNotification(stationName: pretty)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
        }
    }
}
