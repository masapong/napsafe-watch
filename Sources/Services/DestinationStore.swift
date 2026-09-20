import Foundation
import CoreLocation

class DestinationStore: ObservableObject {
    @Published var favorites: [Destination] = []
    @Published var recent: [Destination] = []
    @Published var topUsed: [Destination] = []

    private let favoritesKey = "favorites"
    private let recentKey = "recent"
    private let topUsedKey = "topUsed"

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
        // Update recent
        recent.removeAll { $0.id == destination.id }
        var updated = destination
        updated.lastUsed = Date()
        updated.useCount += 1
        recent.insert(updated, at: 0)
        if recent.count > 10 { recent.removeLast() }

        // Update top used
        if let idx = topUsed.firstIndex(where: { $0.id == destination.id }) {
            topUsed[idx] = updated
        } else {
            topUsed.append(updated)
        }
        topUsed.sort { $0.useCount > $1.useCount }
        if topUsed.count > 5 { topUsed.removeLast() }

        save()
    }

    static let defaultStations: [Destination] = [
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

    func isFavorite(_ destination: Destination) -> Bool {
        favorites.contains(where: { $0.id == destination.id })
    }

    func toggleFavorite(_ destination: Destination) {
        if isFavorite(destination) {
            removeFavorite(destination)
        } else {
            addFavorite(destination)
        }
    }

    func deleteRecent(_ destination: Destination) {
        recent.removeAll { $0.id == destination.id }
        save()
    }

    func clearRecent() {
        recent.removeAll()
        save()
    }

    func nearbyDestinations(current: CLLocationCoordinate2D, limit: Int = 5) -> [Destination] {
        Self.defaultStations.sorted {
            let d1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
            let d2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
            return d1 < d2
        }.prefix(limit).map { $0 }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Destination].self, from: data) {
            favorites = decoded
        }
        if let data = UserDefaults.standard.data(forKey: recentKey),
           let decoded = try? JSONDecoder().decode([Destination].self, from: data) {
            recent = decoded
        }
        if let data = UserDefaults.standard.data(forKey: topUsedKey),
           let decoded = try? JSONDecoder().decode([Destination].self, from: data) {
            topUsed = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: recentKey)
        }
        if let data = try? JSONEncoder().encode(topUsed) {
            UserDefaults.standard.set(data, forKey: topUsedKey)
        }
    }
}
