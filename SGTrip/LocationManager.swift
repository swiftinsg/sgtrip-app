import SwiftUI
import CoreLocation
import Combine

/// Manages location services and publishes user location status to SwiftUI views.
/// Uses `CLLocationManager` with delegation pattern and `@Published` properties
/// for SwiftUI observation.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    /// The underlying Core Location manager handling all location services.
    private let manager = CLLocationManager()

    /// Published user location that SwiftUI views can observe and react to.
    /// Updates when `locationManager(_:didUpdateLocations:)` is called.
    @Published var userLocation: CLLocation?

    /// Current Core Location authorization status.
    /// Published so the UI can show/hide location-dependent features.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Error message from location manager, if any.
    /// Published to display errors to the user (e.g., location denied).
    @Published var locationError: String?

    /// Initializes the LocationManager and sets up the delegate.
    /// - Sets desired accuracy to best available.
    /// - Assigns self as the delegate for location events.
    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Requests when-in-use authorization from the user.
    /// This prompts the system authorization dialog.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Starts the location manager begins updating the user's location.
    /// - First requests permission (if not already authorized).
    /// - Then starts delivering location updates via the delegate.
    func startUpdatingLocation() {
        requestPermission()
        manager.startUpdatingLocation()
    }

    /// Stops the location manager from delivering further updates.
    /// Useful when the view disappears or location is no longer needed.
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    /// Called when the user changes location authorization status (e.g., from
    /// `.notDetermined` to `.authorizedWhenInUse`).
    /// - Updates the `authorizationStatus` published property.
    /// - If authorized, starts location updates immediately.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Called when new location data is available from the location manager.
    /// - Updates the published `userLocation` with the most recent location.
    /// - Clears any previous error state.
    /// - Takes the last object from the `locations` array as it's the most recent.
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        userLocation = locations.last
        locationError = nil
    }

    /// Called when the location manager fails to retrieve a location.
    /// - Stores the error localized description in the published `locationError`.
    /// - Views can display this error to the user.
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationError = error.localizedDescription
    }
}