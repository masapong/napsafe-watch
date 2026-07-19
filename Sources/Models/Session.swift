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

struct NapSession: Identifiable, Codable {
    let id: UUID
    var destination: Destination
    var alertDistance: Double // meters
    var transportMode: TransportMode
    var startTime: Date
    var isActive: Bool

    init(id: UUID = UUID(), destination: Destination, alertDistance: Double = 800, transportMode: TransportMode = .train, startTime: Date = Date()) {
        self.id = id
        self.destination = destination
        self.alertDistance = alertDistance
        self.transportMode = transportMode
        self.startTime = startTime
        self.isActive = true
    }

    var alertDistanceLabel: String {
        if alertDistance >= 1000 {
            return "\(Int(alertDistance / 1000)) km"
        }
        return "\(Int(alertDistance)) m"
    }
}
