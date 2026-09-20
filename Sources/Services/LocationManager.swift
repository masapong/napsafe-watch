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

    /// Called on the main queue when distance drops to or below the alert threshold.
    var onProximityReached: (() -> Void)?

    private var trackedDestination: Destination?
    private var alertDistance: Double = 800
    private var pendingStart: (destination: Destination, alertDistance: Double)?
    private var hasFiredProximity = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.allowsBackgroundLocationUpdates = true
        // Napping looks "stationary"; do not let the system pause updates.
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .otherNavigation
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking(destination: Destination, alertDistance: Double) {
        trackedDestination = destination
        self.alertDistance = alertDistance
        hasFiredProximity = false
        distanceToDestination = nil

        guard isAuthorized else {
            pendingStart = (destination, alertDistance)
            requestAuthorization()
            return
        }

        pendingStart = nil
        isTracking = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        pendingStart = nil
        trackedDestination = nil
        hasFiredProximity = false
        manager.stopUpdatingLocation()
        distanceToDestination = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        updateDistanceIfTracking(from: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .denied, .restricted:
            errorMessage = "Location access denied. Enable in Settings."
        case .authorizedAlways, .authorizedWhenInUse:
            errorMessage = nil
            if let pending = pendingStart {
                startTracking(destination: pending.destination, alertDistance: pending.alertDistance)
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }

    func distance(to destination: Destination) -> Double? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: destination.location)
    }

    private var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    private func updateDistanceIfTracking(from location: CLLocation) {
        guard isTracking, let destination = trackedDestination else { return }
        let meters = location.distance(from: destination.location)
        distanceToDestination = meters
        guard meters <= alertDistance, !hasFiredProximity else { return }
        hasFiredProximity = true
        DispatchQueue.main.async { [weak self] in
            self?.onProximityReached?()
        }
    }
}
