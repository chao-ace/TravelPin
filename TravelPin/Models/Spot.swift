import Foundation
import SwiftData
import CoreLocation

@Model
final class Spot {
    var id: UUID = UUID()
    var name: String = ""

    // Stored as raw values for SwiftData compatibility
    var typeRaw: String = SpotType.sightseeing.rawValue
    var statusRaw: String = SpotStatus.wishing.rawValue

    var estimatedDate: Date?
    var actualDate: Date?
    var sequence: Int = 1
    var notes: String = ""
    var photoPaths: [String] = []
    @Attribute(.externalStorage) var photoData: [Data] = []

    var latitude: Double?
    var longitude: Double?
    @Attribute(.externalStorage) var mapSnapshot: Data?

    // Rich data fields
    var rating: Int?
    var address: String?
    var tags: [String] = []
    var cost: Double?
    var visitDuration: Int? // minutes

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Computed accessors
    var type: SpotType {
        get { SpotType(rawValue: typeRaw) ?? .sightseeing }
        set { typeRaw = newValue.rawValue }
    }

    var status: SpotStatus {
        get { SpotStatus(rawValue: statusRaw) ?? .wishing }
        set { statusRaw = newValue.rawValue }
    }

    var travel: Travel?
    var itinerary: Itinerary?

    init(name: String, type: SpotType = .sightseeing, status: SpotStatus = .wishing, estimatedDate: Date? = nil, actualDate: Date? = nil, sequence: Int = 1, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.statusRaw = status.rawValue
        self.estimatedDate = estimatedDate
        self.actualDate = actualDate
        self.sequence = sequence
        self.notes = notes
    }
}

enum SpotType: String, CaseIterable, Codable {
    case food = "Food"
    case sightseeing = "Sightseeing"
    case shopping = "Shopping"
    case performance = "Performance"
    case fun = "Fun"
    case hotel = "Hotel"
    case travel = "Travel"

    var displayName: String {
        switch self {
        case .food: return "美食"
        case .sightseeing: return "景点"
        case .shopping: return "购物"
        case .performance: return "演出"
        case .fun: return "游玩"
        case .hotel: return "住宿"
        case .travel: return "出行"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .sightseeing: return "binoculars"
        case .shopping: return "cart"
        case .performance: return "ticket"
        case .fun: return "star"
        case .hotel: return "bed.double"
        case .travel: return "bus"
        }
    }
}

enum SpotStatus: String, CaseIterable, Codable {
    case wishing = "Wishing"
    case planning = "Planning"
    case traveling = "Traveling"
    case travelled = "Travelled"
    case cancelled = "Cancelled"

    var displayName: String {
        switch self {
        case .wishing: return "愿望清单"
        case .planning: return "计划中"
        case .traveling: return "出行中"
        case .travelled: return "已出行"
        case .cancelled: return "已取消"
        }
    }
}
