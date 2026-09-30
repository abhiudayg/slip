import CoreLocation
import Foundation

/// Reads location authorization for UI labels. Requests go through PassGeofenceManager.
enum LocationAccess {
    static var status: CLAuthorizationStatus {
        CLLocationManager().authorizationStatus
    }

    static var shortLabel: String {
        switch status {
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "While Using"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not asked"
        @unknown default:
            return "Unknown"
        }
    }

    static var isGranted: Bool {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
}
