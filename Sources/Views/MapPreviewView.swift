import SwiftUI
import MapKit

struct MapPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    let destination: Destination

    @State private var position: MapCameraPosition
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

    init(destination: Destination) {
        self.destination = destination
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: destination.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Marker(destination.name, coordinate: destination.coordinate)
                    .tint(.red)
                UserAnnotation()
            }
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    zoomButton(systemName: "plus") {
                        zoom(by: 0.5)
                    }

                    zoomButton(systemName: "minus") {
                        zoom(by: 2.0)
                    }
                }
                .padding(6)
                .background(.black.opacity(0.72), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                }
                .padding(.top, 22)
                .padding(.trailing, 4)
            }
            .navigationTitle(destination.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                centerOnBoth()
            }
        }
    }

    private func zoomButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.18), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemName == "plus" ? "Zoom in" : "Zoom out")
    }

    private func zoom(by factor: Double) {
        let center = destination.coordinate
        currentSpan = MKCoordinateSpan(
            latitudeDelta: max(0.001, currentSpan.latitudeDelta * factor),
            longitudeDelta: max(0.001, currentSpan.longitudeDelta * factor)
        )
        position = .region(MKCoordinateRegion(center: center, span: currentSpan))
    }

    private func centerOnBoth() {
        guard let current = locationManager.currentLocation?.coordinate else { return }
        let minLat = min(current.latitude, destination.coordinate.latitude)
        let maxLat = max(current.latitude, destination.coordinate.latitude)
        let minLon = min(current.longitude, destination.coordinate.longitude)
        let maxLon = max(current.longitude, destination.coordinate.longitude)

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.001),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.001)
        )
        currentSpan = span
        position = .region(MKCoordinateRegion(center: center, span: span))
    }
}
