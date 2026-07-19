import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var distanceToDestination: Double?
    @Published var errorMessage: String?

    var onProximityReached: (() -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.allowsBackgroundLocationUpdates = true
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking(destination: Destination, alertDistance: Double) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            requestAuthorization()
            return
        }
        isTracking = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
        distanceToDestination = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .denied || status == .restricted {
            errorMessage = "Location access denied. Enable in Settings."
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }

    func distance(to destination: Destination) -> Double? {
        guard let current = currentLocation else { return nil }
        let destLoc = CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude)
        return current.distance(from: destLoc)
    }
}
