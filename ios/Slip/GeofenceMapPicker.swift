import CoreLocation
import MapKit
import SwiftUI

/// Drop a pin to set geofence coordinates (fills `latitude` / `longitude`).
/// Defaults to the user's current location when available, with place search.
struct GeofenceMapPicker: View {
    @Binding var latitude: String
    @Binding var longitude: String
    var placeHint: String = ""
    var onDismiss: () -> Void

    @StateObject private var locator = CurrentLocationProvider()
    @StateObject private var placeSearch = PlaceSearchModel()

    @State private var camera: MapCameraPosition = .automatic
    @State private var pin = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
    @State private var resolvedName = ""
    @State private var searchText = ""
    @State private var didSetInitialCamera = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $camera) {
                    Marker(resolvedName.isEmpty ? "Venue" : resolvedName, coordinate: pin)
                        .tint(.red)
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    pin = context.camera.centerCoordinate
                    updateCoordStrings()
                    reverseGeocode(pin)
                }

                // Crosshair so the center is the drop target.
                Image(systemName: "mappin")
                    .font(.slipSystem(size: 36, weight: .semibold))
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                    .offset(y: -18)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    searchChrome
                    Spacer()
                    bottomCard
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
            .onChange(of: locator.coordinate) { _, coord in
                guard let coord, !didSetInitialCamera else { return }
                // Only auto-center when no explicit coords were already provided.
                if hasExistingCoords { return }
                center(on: coord, spanMeters: 900)
                didSetInitialCamera = true
            }
            .onChange(of: searchText) { _, query in
                placeSearch.updateQuery(query, near: pin)
            }
        }
    }

    // MARK: - Chrome

    private var searchChrome: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(SlipTheme.muted)
                TextField("Search places", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit { commitTypedSearch() }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        placeSearch.clear()
                        searchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if searchFocused && !placeSearch.completions.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(placeSearch.completions.enumerated()), id: \.offset) { _, item in
                            Button {
                                selectCompletion(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(SlipTheme.ink)
                                    if !item.subtitle.isEmpty {
                                        Text(item.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(SlipTheme.muted)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider().background(SlipTheme.glassBorder)
                        }
                    }
                }
                .frame(maxHeight: 220)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
    }

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resolvedName.isEmpty ? "Drag the map to place the pin" : resolvedName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(2)
            Text(String(format: "%.5f, %.5f", pin.latitude, pin.longitude))
                .font(.caption.monospaced())
                .foregroundStyle(SlipTheme.muted)
            Text("Search a place, or drag the map. Pin uses the map center.")
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
    }

    // MARK: - Bootstrap

    private var hasExistingCoords: Bool {
        guard let lat = Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)),
              let lon = Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)),
              abs(lat) <= 90, abs(lon) <= 180 else { return false }
        // Treat 0,0 as unset.
        return !(abs(lat) < 0.0001 && abs(lon) < 0.0001)
    }

    private func bootstrap() {
        locator.request()
        if hasExistingCoords,
           let lat = Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)),
           let lon = Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)) {
            center(on: CLLocationCoordinate2D(latitude: lat, longitude: lon), spanMeters: 900)
            didSetInitialCamera = true
            reverseGeocode(pin)
            return
        }
        if let current = locator.coordinate {
            center(on: current, spanMeters: 900)
            didSetInitialCamera = true
            return
        }
        if !placeHint.isEmpty {
            geocodeHint(placeHint)
            didSetInitialCamera = true
            return
        }
        // Temporary fallback until Core Location replies (or if permission denied).
        center(on: pin, spanMeters: 2500)
    }

    private func center(on coordinate: CLLocationCoordinate2D, spanMeters: CLLocationDistance) {
        pin = coordinate
        camera = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: spanMeters, longitudinalMeters: spanMeters))
        updateCoordStrings()
        reverseGeocode(coordinate)
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
            center(on: item.location.coordinate, spanMeters: 1200)
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        searchText = completion.title
        searchFocused = false
        placeSearch.clear()
        let request = MKLocalSearch.Request(completion: completion)
        Task { @MainActor in
            guard let response = try? await MKLocalSearch(request: request).start(),
                  let item = response.mapItems.first else { return }
            didSetInitialCamera = true
            center(on: item.location.coordinate, spanMeters: 900)
            if let name = item.name, !name.isEmpty {
                resolvedName = name
            }
        }
    }

    private func commitTypedSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        searchFocused = false
        placeSearch.clear()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: pin, latitudinalMeters: 40_000, longitudinalMeters: 40_000)
        Task { @MainActor in
            guard let response = try? await MKLocalSearch(request: request).start(),
                  let item = response.mapItems.first else { return }
            didSetInitialCamera = true
            center(on: item.location.coordinate, spanMeters: 900)
            if let name = item.name, !name.isEmpty {
                resolvedName = name
            }
        }
    }
}

// MARK: - Current location

@MainActor
final class CurrentLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if let loc = manager.location {
            coordinate = loc.coordinate
        }
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            coordinate = loc.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep fallback pin; search still works.
    }
}

// MARK: - Place search

@MainActor
final class PlaceSearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var completions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String, near coordinate: CLLocationCoordinate2D) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            completions = []
            completer.queryFragment = ""
            return
        }
        completer.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 50_000,
            longitudinalMeters: 50_000
        )
        completer.queryFragment = trimmed
    }

    func clear() {
        completions = []
        completer.queryFragment = ""
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = Array(completer.results.prefix(8))
        Task { @MainActor in
            completions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            completions = []
        }
    }
}
