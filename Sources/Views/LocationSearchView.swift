import SwiftUI
import CoreLocation
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (Destination) -> Void

    @State private var query = ""
    @State private var results: [Destination] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    private let debounceNanoseconds: UInt64 = 300_000_000

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Station or address", text: $query)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    .onChange(of: query) { _, newValue in
                        search(query: newValue)
                    }

                if isSearching {
                    ProgressView()
                        .padding()
                } else if results.isEmpty && !query.isEmpty {
                    Text("No results")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(results) { dest in
                        Button {
                            onSelect(dest)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(dest.name)
                                if let addr = dest.address {
                                    Text(addr).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { results = [] }
        .onDisappear { searchTask?.cancel() }
    }

    private func search(query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = [.address, .pointOfInterest]

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                guard !Task.isCancelled else { return }

                let destinations = response.mapItems.map { item in
                    Destination(
                        name: item.name ?? "Unknown",
                        coordinate: item.placemark.coordinate,
                        address: formatAddress(from: item.placemark)
                    )
                }

                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    results = destinations
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    results = []
                    isSearching = false
                }
            }
        }
    }

    private func formatAddress(from placemark: MKPlacemark) -> String? {
        let parts = [placemark.locality, placemark.subLocality, placemark.thoroughfare, placemark.subThoroughfare]
            .compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
