import CoreLocation
import MapKit
import SwiftUI

/// Drop a pin to set geofence coordinates (fills `latitude` / `longitude`).
struct GeofenceMapPicker: View {
    @Binding var latitude: String
    @Binding var longitude: String
    var placeHint: String = ""
    var onDismiss: () -> Void

    @State private var camera: MapCameraPosition = .automatic
    @State private var pin = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
    @State private var resolvedName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $camera) {
                    Marker(resolvedName.isEmpty ? "Venue" : resolvedName, coordinate: pin)
                        .tint(.red)
                }
                .mapStyle(.standard(elevation: .realistic))
                .onMapCameraChange(frequency: .onEnd) { context in
                    pin = context.camera.centerCoordinate
                    updateCoordStrings()
                    reverseGeocode(pin)
                }

                // Crosshair so the center is the drop target.
                Image(systemName: "mappin")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                    // Map pin glyph hotspot (tip), not screen layout.
                    .offset(y: -18)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resolvedName.isEmpty ? "Drag the map to place the pin" : resolvedName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .lineLimit(2)
                        Text(String(format: "%.5f, %.5f", pin.latitude, pin.longitude))
                            .font(.caption.monospaced())
                            .foregroundStyle(SlipTheme.muted)
                        Text("Latitude & longitude update as you move the map.")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Drop venue pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Pin") {
                        updateCoordStrings()
                        SlipHaptics.shareReady()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { bootstrap() }
        }
    }

    private func bootstrap() {
        if let lat = Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)),
           let lon = Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)),
           abs(lat) <= 90, abs(lon) <= 180 {
            pin = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            camera = .region(MKCoordinateRegion(center: pin, latitudinalMeters: 900, longitudinalMeters: 900))
            reverseGeocode(pin)
            return
        }
        // Default: Bengaluru CBD — user pans to venue.
        pin = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        camera = .region(MKCoordinateRegion(center: pin, latitudinalMeters: 2500, longitudinalMeters: 2500))
        if !placeHint.isEmpty {
            geocodeHint(placeHint)
        }
    }

    private func updateCoordStrings() {
        latitude = String(format: "%.6f", pin.latitude)
        longitude = String(format: "%.6f", pin.longitude)
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        Task { @MainActor in
            guard let item = try? await request.mapItems.first else { return }
            let parts = [item.name, item.address?.shortAddress, item.address?.fullAddress]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            resolvedName = parts.prefix(2).joined(separator: ", ")
        }
    }

    private func geocodeHint(_ hint: String) {
        guard let request = MKGeocodingRequest(addressString: hint) else { return }
        Task { @MainActor in
            guard let item = try? await request.mapItems.first else { return }
            pin = item.location.coordinate
            camera = .region(MKCoordinateRegion(center: pin, latitudinalMeters: 1200, longitudinalMeters: 1200))
            updateCoordStrings()
            reverseGeocode(pin)
        }
    }
}
