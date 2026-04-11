import Foundation
import ActivityKit

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that changes during the activity
        var currentSpotName: String
        var nextSpotName: String?
        var distanceToNext: Double? // in KM
        var arrivalEstimate: Date?
        var weatherIcon: String?
        var temperature: Double?
    }

    // Fixed data that doesn't change
    var tripName: String
    var startDate: Date
}
