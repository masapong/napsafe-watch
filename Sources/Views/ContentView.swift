import SwiftUI

struct ContentView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedDestination: Destination?
    @State private var showSearch = false
    @State private var alertDistance: Double = 800

    var body: some View {
        NavigationStack {
            if let session = sessionManager.activeSession {
                ActiveSessionView(session: session)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        header

                        destinationSection(title: "Nearby", destinations: nearby)

                        destinationSection(title: "Favorites", destinations: destinationStore.favorites)

                        destinationSection(title: "Most Used", destinations: destinationStore.topUsed)

                        destinationSection(title: "Recent", destinations: destinationStore.recent)

                        Button {
                            showSearch = true
                        } label: {
                            Label("Search Destination", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .padding()
                }
                .navigationTitle("Napsafe")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showSearch) {
                    LocationSearchView { dest in
                        selectedDestination = dest
                    }
                }
                .sheet(item: $selectedDestination) { dest in
                    AlertSettingsView(destination: dest, alertDistance: $alertDistance) { session in
                        beginSession(session, destination: dest)
                    }
                }
                .onChange(of: selectedDestination) { _, newValue in
                    if newValue != nil {
                        showSearch = false
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
            sessionManager.requestNotificationAuthorization()
        }
    }

    private func beginSession(_ session: NapSession, destination: Destination) {
        locationManager.onProximityReached = { [weak sessionManager] in
            sessionManager?.triggerAlert()
        }
        sessionManager.startSession(session)
        destinationStore.recordUse(destination)
        locationManager.startTracking(destination: destination, alertDistance: session.alertDistance)
        selectedDestination = nil
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 32))
                .foregroundStyle(.cyan)
            Text("Nap safely on transit")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if sessionManager.totalNapMinutes > 0 {
                Text(formatTotalNapTime(sessionManager.totalNapMinutes))
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                    .onLongPressGesture {
                        sessionManager.resetTotalNapTime()
                    }
            }
        }
        .padding(.vertical, 8)
    }

    private func formatTotalNapTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "Total: \(hours)h \(mins)m (hold to reset)"
        }
        return "Total: \(mins)m (hold to reset)"
    }

    private var nearby: [Destination] {
        if let loc = locationManager.currentLocation?.coordinate {
            return destinationStore.nearbyDestinations(current: loc)
        }
        return []
    }

    private func destinationSection(title: String, destinations: [Destination]) -> some View {
        Group {
            if !destinations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    ForEach(destinations) { dest in
                        DestinationRow(destination: dest) {
                            selectedDestination = dest
                        }
                    }
                }
            }
        }
    }
}

struct DestinationRow: View {
    let destination: Destination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if let addr = destination.address {
                        Text(addr)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
