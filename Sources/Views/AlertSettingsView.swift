import SwiftUI

struct AlertSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var destinationStore: DestinationStore
    let destination: Destination
    @Binding var alertDistance: Double
    var onStart: (NapSession) -> Void

    @State private var transportMode: TransportMode = .train
    @State private var showMap = false

    let distances: [Double] = NapSession.presetAlertDistances

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    destinationCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alert me")
                            .font(.headline)
                        Picker("", selection: $alertDistance) {
                            ForEach(distances, id: \.self) { d in
                                Text(d.formattedDistance).tag(d)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 80)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transport")
                            .font(.headline)
                        Picker("Mode", selection: $transportMode) {
                            ForEach(TransportMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 60)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        showMap = true
                    } label: {
                        Label("Preview on Map", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let session = NapSession(
                            destination: destination,
                            alertDistance: alertDistance,
                            transportMode: transportMode
                        )
                        onStart(session)
                        dismiss()
                    } label: {
                        Label("Start Napsafe", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showMap) {
                MapPreviewView(destination: destination)
            }
        }
    }

    private var destinationCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name)
                    .font(.title3.bold())
                if let addr = destination.address {
                    Text(addr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                destinationStore.toggleFavorite(destination)
            } label: {
                Image(systemName: destinationStore.isFavorite(destination) ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(.yellow)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(destinationStore.isFavorite(destination) ? "Remove from favorites" : "Add to favorites")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
