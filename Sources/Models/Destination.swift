import Foundation
import CoreLocation

struct Destination: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    var address: String?
    var lastUsed: Date
    var useCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        lastUsed: Date = Date(),
        useCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.lastUsed = lastUsed
        self.useCount = useCount
    }

    /// Convenience for CoreLocation distance calculations.
    var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, address, lastUsed, useCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        lastUsed = try container.decode(Date.self, forKey: .lastUsed)
        useCount = try container.decode(Int.self, forKey: .useCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(lastUsed, forKey: .lastUsed)
        try container.encode(useCount, forKey: .useCount)
    }
}
