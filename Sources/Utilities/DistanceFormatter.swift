import Foundation
import CoreLocation

extension Double {
    /// Formats a distance in meters to a readable string with unit (e.g. "500 m", "1.5 km", "2 km").
    var formattedDistance: String {
        if self >= 1000 {
            let km = self / 1000.0
            if km.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(km)) km"
            } else {
                return String(format: "%.1f km", km)
            }
        } else {
            return "\(Int(max(0, self.rounded()))) m"
        }
    }
}
