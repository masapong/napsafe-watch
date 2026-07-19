import SwiftUI
import CoreLocation
import MapKit
import UIKit

struct ActiveSessionView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sessionManager: SessionManager
    let session: NapSession

    @State private var distance: Double?
    @State private var timer: Timer?
    @State private var mapImage: UIImage?
    @State private var mapUpdateTimer: Timer?
    @State private var napMinutes: Int = 0

    var body: some View {
        ZStack {
            // Map background (subtle)
            if let img = mapImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Dark overlay to make UI readable
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
                            Text(formatDistance(d))
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
            startDistanceUpdates()
            startMapUpdates()
        }
        .onDisappear {
            timer?.invalidate()
            mapUpdateTimer?.invalidate()
        }
    }

    private func startDistanceUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            if let d = locationManager.distance(to: session.destination) {
                distance = d
                if d <= session.alertDistance && !sessionManager.isAlerting {
                    sessionManager.triggerAlert()
                }
            }
            // Update nap duration
            let elapsedMin = Int(Date().timeIntervalSince(session.startTime) / 60)
            if elapsedMin != napMinutes { napMinutes = elapsedMin }
        }
        timer?.fire()
    }

    private func stopSession() {
        timer?.invalidate()
        locationManager.stopTracking()
        sessionManager.endSession()
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters)) m"
    }

    private func startMapUpdates() {
        updateMapImage()
        mapUpdateTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            updateMapImage()
        }
    }

    private func updateMapImage() {
        let dest = session.destination.coordinate
        let current = locationManager.currentLocation?.coordinate ?? dest

        // Calculate region encompassing both points with padding
        let minLat = min(current.latitude, dest.latitude) - 0.01
        let maxLat = max(current.latitude, dest.latitude) + 0.01
        let minLon = min(current.longitude, dest.longitude) - 0.01
        let maxLon = max(current.longitude, dest.longitude) + 0.01

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: maxLat - minLat,
            longitudeDelta: maxLon - minLon
        )
        let region = MKCoordinateRegion(center: center, span: span)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 400)
        options.scale = 2.0

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else { return }
            DispatchQueue.main.async {
                self.mapImage = snapshot.image
            }
        }
    }
}
