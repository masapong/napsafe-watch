import Foundation
import CoreLocation

class DestinationStore: ObservableObject {
    @Published var favorites: [Destination] = []
    @Published var recent: [Destination] = []
    @Published var topUsed: [Destination] = []

    private let favoritesKey = "favorites"
    private let recentKey = "recent"
    private let topUsedKey = "topUsed"

    private let recentLimit = 10
    private let topUsedLimit = 5

    /// Curated transit hubs used for Nearby suggestions (stable across launches).
    static let knownStations: [Destination] = [
        Destination(name: "Tokyo Station", coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671), address: "Marunouchi, Chiyoda-ku"),
        Destination(name: "Shinjuku Station", coordinate: CLLocationCoordinate2D(latitude: 35.6896, longitude: 139.7006), address: "Shinjuku-ku"),
        Destination(name: "Shibuya Station", coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016), address: "Shibuya-ku"),
        Destination(name: "Ikebukuro Station", coordinate: CLLocationCoordinate2D(latitude: 35.7303, longitude: 139.7110), address: "Toshima-ku"),
        Destination(name: "Nishi-Ogikubo Station", coordinate: CLLocationCoordinate2D(latitude: 35.7042, longitude: 139.6004), address: "Suginami-ku"),
        Destination(name: "Kichijoji Station", coordinate: CLLocationCoordinate2D(latitude: 35.7034, longitude: 139.5799), address: "Musashino-shi"),
        Destination(name: "Mitaka Station", coordinate: CLLocationCoordinate2D(latitude: 35.7033, longitude: 139.5608), address: "Mitaka-shi"),
        Destination(name: "Koenji Station", coordinate: CLLocationCoordinate2D(latitude: 35.7058, longitude: 139.6494), address: "Suginami-ku"),
        Destination(name: "Nakano Station", coordinate: CLLocationCoordinate2D(latitude: 35.7075, longitude: 139.6639), address: "Nakano-ku"),
        Destination(name: "Tachikawa Station", coordinate: CLLocationCoordinate2D(latitude: 35.6981, longitude: 139.4132), address: "Tachikawa-shi"),
        Destination(name: "Yokohama Station", coordinate: CLLocationCoordinate2D(latitude: 35.4658, longitude: 139.6224), address: "Nishi-ku, Yokohama"),
        Destination(name: "Kawasaki Station", coordinate: CLLocationCoordinate2D(latitude: 35.5311, longitude: 139.6970), address: "Kawasaki-ku"),
        Destination(name: "Omiya Station", coordinate: CLLocationCoordinate2D(latitude: 35.9061, longitude: 139.6233), address: "Omiya-ku, Saitama"),
        Destination(name: "Ueno Station", coordinate: CLLocationCoordinate2D(latitude: 35.7138, longitude: 139.7773), address: "Taito-ku"),
        Destination(name: "Akihabara Station", coordinate: CLLocationCoordinate2D(latitude: 35.6984, longitude: 139.7731), address: "Chiyoda-ku"),
        Destination(name: "Osaka Station", coordinate: CLLocationCoordinate2D(latitude: 34.7024, longitude: 135.4959), address: "Umeda, Kita-ku"),
        Destination(name: "Kyoto Station", coordinate: CLLocationCoordinate2D(latitude: 34.9858, longitude: 135.7588), address: "Shimogyo-ku, Kyoto"),
        Destination(name: "Nagoya Station", coordinate: CLLocationCoordinate2D(latitude: 35.1709, longitude: 136.8815), address: "Nakamura-ku, Nagoya"),
        Destination(name: "Hiroshima Station", coordinate: CLLocationCoordinate2D(latitude: 34.3979, longitude: 132.4756), address: "Minami-ku, Hiroshima"),
        Destination(name: "Fukuoka Station", coordinate: CLLocationCoordinate2D(latitude: 33.5899, longitude: 130.4206), address: "Hakata-ku, Fukuoka"),
    ]

    init() {
        load()
    }

    func addFavorite(_ destination: Destination) {
        if !favorites.contains(where: { $0.id == destination.id }) {
            favorites.append(destination)
            save()
        }
    }

    func removeFavorite(_ destination: Destination) {
        favorites.removeAll { $0.id == destination.id }
        save()
    }

    func recordUse(_ destination: Destination) {
        var updated = destination
        updated.lastUsed = Date()
        updated.useCount += 1

        recent.removeAll { $0.id == updated.id }
        recent.insert(updated, at: 0)
        if recent.count > recentLimit {
            recent = Array(recent.prefix(recentLimit))
        }

        if let idx = topUsed.firstIndex(where: { $0.id == updated.id }) {
            topUsed[idx] = updated
        } else {
            topUsed.append(updated)
        }
        topUsed.sort { $0.useCount > $1.useCount }
        if topUsed.count > topUsedLimit {
            topUsed = Array(topUsed.prefix(topUsedLimit))
        }

        if let idx = favorites.firstIndex(where: { $0.id == updated.id }) {
            favorites[idx] = updated
        }

        save()
    }

    func nearbyDestinations(current: CLLocationCoordinate2D, limit: Int = 5) -> [Destination] {
        let origin = CLLocation(latitude: current.latitude, longitude: current.longitude)
        return Self.knownStations
            .sorted { $0.location.distance(from: origin) < $1.location.distance(from: origin) }
            .prefix(limit)
            .map { $0 }
    }

    private func load() {
        favorites = decodeDestinations(forKey: favoritesKey)
        recent = decodeDestinations(forKey: recentKey)
        topUsed = decodeDestinations(forKey: topUsedKey)
    }

    private func save() {
        encode(favorites, forKey: favoritesKey)
        encode(recent, forKey: recentKey)
        encode(topUsed, forKey: topUsedKey)
    }

    private func decodeDestinations(forKey key: String) -> [Destination] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Destination].self, from: data) else {
            return []
        }
        return decoded
    }

    private func encode(_ destinations: [Destination], forKey key: String) {
        guard let data = try? JSONEncoder().encode(destinations) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
