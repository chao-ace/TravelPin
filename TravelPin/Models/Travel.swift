import Foundation
import SwiftData

@Model
final class Travel {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(86400 * 3)

    // Stored as raw values for SwiftData compatibility
    var statusRaw: String = TravelStatus.wishing.rawValue
    var typeRaw: String = TravelType.tourism.rawValue

    var companionNames: [String] = []
    var travelPhotos: [String] = []

    @Relationship(deleteRule: .cascade, inverse: \Itinerary.travel)
    var itineraries: [Itinerary] = []

    @Relationship(deleteRule: .cascade, inverse: \Spot.travel)
    var spots: [Spot] = []

    @Relationship(deleteRule: .cascade, inverse: \LuggageItem.travel)
    var luggageItems: [LuggageItem] = []

    // Computed accessors
    var status: TravelStatus {
        get { TravelStatus(rawValue: statusRaw) ?? .wishing }
        set { statusRaw = newValue.rawValue }
    }

    var type: TravelType {
        get { TravelType(rawValue: typeRaw) ?? .tourism }
        set { typeRaw = newValue.rawValue }
    }

    init(name: String, startDate: Date = Date(), endDate: Date = Date().addingTimeInterval(86400 * 3), status: TravelStatus = .wishing, type: TravelType = .tourism) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = status.rawValue
        self.typeRaw = type.rawValue
    }
}

enum TravelStatus: String, CaseIterable, Codable {
    case wishing = "Wishing"
    case planning = "Planning"
    case traveling = "Traveling"
    case travelled = "Travelled"
    case cancelled = "Cancelled"

    var displayName: String {
        return "status.\(self.rawValue.lowercased())".localized
    }

    var colorName: String {
        switch self {
        case .wishing: return "blue"
        case .planning: return "orange"
        case .traveling: return "green"
        case .travelled: return "gray"
        case .cancelled: return "red"
        }
    }
}

enum TravelType: String, CaseIterable, Codable {
    case tourism = "Tourism"
    case concert = "Concert"
    case chill = "Chill"
    case business = "Business"
    case other = "Other"

    var displayName: String {
        return "type.\(self.rawValue.lowercased())".localized
    }

    var icon: String {
        switch self {
        case .tourism: return "airplane"
        case .concert: return "music.note"
        case .chill: return "beach.umbrella"
        case .business: return "briefcase"
        case .other: return "map"
        }
    }
}
