import Foundation
import CoreLocation

enum TransportMode: String, Codable, CaseIterable {
    case train = "Train"
    case subway = "Subway"
    case bus = "Bus"

    var icon: String {
        switch self {
        case .train: return "tram.fill"
        case .subway: return "tram.tunnel.fill"
        case .bus: return "bus.fill"
        }
    }
}

enum DistanceFormat {
    /// Short label for pickers / HUD (e.g. "800 m", "1 km", "1.5 km").
    static func label(meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            if km.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(km)) km"
            }
            return String(format: "%g km", km)
        }
        return "\(Int(meters)) m"
    }

    /// Live distance readout with one decimal for km (e.g. "1.2 km").
    static func live(meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters)) m"
    }
}

struct NapSession: Identifiable, Codable {
    let id: UUID
    var destination: Destination
    var alertDistance: Double // meters
    var transportMode: TransportMode
    var startTime: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        destination: Destination,
        alertDistance: Double = 800,
        transportMode: TransportMode = .train,
        startTime: Date = Date()
    ) {
        self.id = id
        self.destination = destination
        self.alertDistance = alertDistance
        self.transportMode = transportMode
        self.startTime = startTime
        self.isActive = true
    }

    var alertDistanceLabel: String {
        DistanceFormat.label(meters: alertDistance)
    }
}
