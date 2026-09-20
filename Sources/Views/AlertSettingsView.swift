import SwiftUI

struct AlertSettingsView: View {
    @Environment(\.dismiss) var dismiss
    let destination: Destination
    @Binding var alertDistance: Double
    var onStart: (NapSession) -> Void

    @State private var transportMode: TransportMode = .train
    @State private var showMap = false

    let distances: [Double] = [800, 1000, 1500]

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
                                Text(DistanceFormat.label(meters: d)).tag(d)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(destination.name)
                .font(.title3.bold())
            if let addr = destination.address {
                Text(addr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
