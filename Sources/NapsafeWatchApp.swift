import SwiftUI

@main
struct NapsafeWatchApp: App {
    @StateObject private var destinationStore = DestinationStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(destinationStore)
                .environmentObject(locationManager)
                .environmentObject(sessionManager)
                .onAppear {
                    setupCoordination()
                }
        }
    }

    private func setupCoordination() {
        locationManager.onProximityReached = { [weak sessionManager] in
            sessionManager?.triggerAlert()
        }
        sessionManager.onSessionEnded = { [weak locationManager] in
            locationManager?.stopTracking()
        }
    }
}
