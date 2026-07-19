import SwiftUI

struct ContentView: View {
    @EnvironmentObject var destinationStore: DestinationStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedDestination: Destination?
    @State private var showSearch = false
    @State private var showSettings = false
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
                .sheet(isPresented: $showSettings) {
                    if let dest = selectedDestination {
                        AlertSettingsView(destination: dest, alertDistance: $alertDistance) { session in
                            sessionManager.startSession(session)
                            destinationStore.recordUse(dest)
                            locationManager.startTracking(destination: dest, alertDistance: alertDistance)
                            showSettings = false
                            selectedDestination = nil
                        }
                    }
                }
                .onChange(of: selectedDestination) { _, newValue in
                    if newValue != nil {
                        showSearch = false
                        showSettings = true
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
            sessionManager.requestNotificationAuthorization()
        }
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
                            showSettings = true
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
