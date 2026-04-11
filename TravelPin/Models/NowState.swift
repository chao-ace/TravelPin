import Foundation

/// Rich real-time state for the during-trip "NowPlaying" card.
/// Computed by TravelLogicService.getNowState() and displayed in NowPlayingCard.
struct NowState {
    let currentTime: Date
    let currentSpot: Spot?
    let nextSpot: Spot?
    let distanceToNext: Double?         // meters
    let suggestedDepartureTime: Date?   // when to leave current spot for the next
    let temperature: Double?
    let clothingHint: String?
    let fatigueLevel: FatigueLevel
    let progressVisited: Int
    let progressTotal: Int

    enum FatigueLevel {
        case low, moderate, high

        var label: String {
            switch self {
            case .low:      return "now.fatigue.low".localized
            case .moderate: return "now.fatigue.moderate".localized
            case .high:     return "now.fatigue.high".localized
            }
        }

        var icon: String {
            switch self {
            case .low:      return "bolt.fill"
            case .moderate: return "battery.50"
            case .high:     return "battery.25"
            }
        }

        var color: String {
            switch self {
            case .low:      return "green"
            case .moderate: return "orange"
            case .high:     return "red"
            }
        }
    }

    var progressRatio: Double {
        guard progressTotal > 0 else { return 0 }
        return Double(progressVisited) / Double(progressTotal)
    }

    var distanceText: String? {
        guard let d = distanceToNext else { return nil }
        if d < 1000 {
            return String(format: "%.0f m", d)
        }
        return String(format: "%.1f km", d / 1000.0)
    }

    var departureTimeText: String? {
        suggestedDepartureTime?.formatted(.dateTime.hour().minute())
    }
}
