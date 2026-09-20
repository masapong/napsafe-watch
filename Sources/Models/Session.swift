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

    static let presetAlertDistances: [Double] = [500, 800, 1000, 1500, 2000]

    var alertDistanceLabel: String {
        alertDistance.formattedDistance
    }
}
