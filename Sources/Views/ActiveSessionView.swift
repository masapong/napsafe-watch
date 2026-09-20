import SwiftUI
import CoreLocation
import MapKit
import UIKit

struct ActiveSessionView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sessionManager: SessionManager
    let session: NapSession

    @State private var mapImage: UIImage?
    @State private var mapUpdateTimer: Timer?
    @State private var napTimer: Timer?
    @State private var napMinutes: Int = 0

    private var distance: Double? {
        locationManager.distanceToDestination ?? locationManager.distance(to: session.destination)
    }

    var body: some View {
        ZStack {
            if let mapImage {
                Image(uiImage: mapImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            Color.black
                .ignoresSafeArea()
                .opacity(0.65)

            if sessionManager.isAlerting {
                Color.red
                    .ignoresSafeArea()
                    .opacity(0.4)
            }

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Image(systemName: session.transportMode.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.cyan)
                        Text("Napping to")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(session.destination.name)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                        if napMinutes > 0 {
                            Text("Napping for \(napMinutes) min")
                                .font(.caption2)
                                .foregroundStyle(.cyan)
                        } else {
                            Text("Just started")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 6)

                    if let d = distance {
                        VStack(spacing: 2) {
                            Text(DistanceFormat.live(meters: d))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(d <= session.alertDistance ? .red : .primary)
                            Text("to destination")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        ProgressView("Locating...")
                    }

                    VStack(spacing: 2) {
                        Text("Alert at")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(session.alertDistanceLabel)
                            .font(.headline)
                            .foregroundStyle(.cyan)
                    }

                    if sessionManager.isAlerting {
                        Text("WAKE UP")
                            .font(.title3.bold())
                            .foregroundStyle(.red)
                    }

                    #if DEBUG
                    if !sessionManager.isAlerting {
                        Button {
                            sessionManager.triggerAlert()
                        } label: {
                            Label("Demo Alert", systemImage: "bell.badge")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    #endif

                    Button(role: .destructive) {
                        stopSession()
                    } label: {
                        Label(sessionManager.isAlerting ? "Stop Alarm" : "Cancel", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            locationManager.onProximityReached = { [weak sessionManager] in
                sessionManager?.triggerAlert()
            }
            refreshNapMinutes()
            startNapTimer()
            startMapUpdates()
        }
        .onChange(of: locationManager.distanceToDestination) { _, newDistance in
            guard let d = newDistance,
                  d <= session.alertDistance,
                  !sessionManager.isAlerting else { return }
            sessionManager.triggerAlert()
        }
        .onDisappear {
            invalidateTimers()
        }
    }

    private func startNapTimer() {
        let timer = Timer(timeInterval: 15, repeats: true) { _ in
            refreshNapMinutes()
        }
        RunLoop.main.add(timer, forMode: .common)
        napTimer = timer
    }

    private func refreshNapMinutes() {
        let elapsedMin = Int(Date().timeIntervalSince(session.startTime) / 60)
        if elapsedMin != napMinutes {
            napMinutes = elapsedMin
        }
    }

    private func stopSession() {
        invalidateTimers()
        locationManager.onProximityReached = nil
        locationManager.stopTracking()
        sessionManager.endSession()
    }

    private func invalidateTimers() {
        napTimer?.invalidate()
        napTimer = nil
        mapUpdateTimer?.invalidate()
        mapUpdateTimer = nil
    }

    private func startMapUpdates() {
        updateMapImage()
        let timer = Timer(timeInterval: 120, repeats: true) { _ in
            updateMapImage()
        }
        RunLoop.main.add(timer, forMode: .common)
        mapUpdateTimer = timer
    }

    private func updateMapImage() {
        let dest = session.destination.coordinate
        let current = locationManager.currentLocation?.coordinate ?? dest
        let region = MapRegion.encompassing(current, dest, paddingDegrees: 0.01)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 400)
        options.scale = 2.0

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot, error == nil else { return }
            DispatchQueue.main.async {
                self.mapImage = snapshot.image
            }
        }
    }
}

enum MapRegion {
    static func encompassing(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D,
        paddingDegrees: CLLocationDegrees,
        minimumDelta: CLLocationDegrees = 0.001
    ) -> MKCoordinateRegion {
        let minLat = min(a.latitude, b.latitude) - paddingDegrees
        let maxLat = max(a.latitude, b.latitude) + paddingDegrees
        let minLon = min(a.longitude, b.longitude) - paddingDegrees
        let maxLon = max(a.longitude, b.longitude) + paddingDegrees

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, minimumDelta),
            longitudeDelta: max(maxLon - minLon, minimumDelta)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
