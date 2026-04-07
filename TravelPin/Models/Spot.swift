import Foundation
import SwiftData
import CoreLocation

// MARK: - Spot

/// A highlight location within a `Travel` trip.
///
/// Owned by `Travel` via `Travel.spots` (cascade delete).
/// Optionally grouped into an `Itinerary` day plan via `Spot.itinerary`.
///
/// ## Architecture Notes
/// - Primitive fields stored directly as SwiftData `@Model` properties.
/// - Enum-backed fields use `*Raw` storage with computed proxies (`type`, `status`).
/// - Binary / collection attachments (`photoPaths`, `photos`, `mapSnapshot`) are
///   kept separate from identity fields for clean sync payload generation.
@Model
final class Spot {

    // MARK: - Identity

    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""

    // MARK: - Classification (Enum-Backed)

    /// Raw storage for `SpotType`. Access via computed `type` property.
    var typeRaw: String = SpotType.sightseeing.rawValue
    /// Raw storage for `SpotStatus`. Access via computed `status` property.
    var statusRaw: String = SpotStatus.wishing.rawValue

    // MARK: - Schedule

    /// Planned visit date (user-set or AI-suggested).
    var estimatedDate: Date?
    /// Actual visit date, set when status transitions to `.traveling`.
    var actualDate: Date?
    /// Sort order within the parent travel or itinerary (1-based).
    var sequence: Int = 1

    // MARK: - Location

    var latitude: Double?
    var longitude: Double?

    // MARK: - Notes & Metadata

    var notes: String = ""
    var address: String?
    var tags: [String] = []

    // MARK: - Rating & Cost

    /// User rating, 1-5 scale.
    var rating: Int?
    /// Estimated or actual cost for this spot visit.
    var cost: Double?
    /// Planned visit duration in minutes.
    var visitDuration: Int?

    // MARK: - Media Attachments

    /// Remote photo URLs (populated after cloud sync).
    var photoPaths: [String] = []
    /// Local photo assets stored via SwiftData relationship.
    @Relationship(deleteRule: .cascade)
    var photos: [TravelPhoto]
    
    /// Rendered static map snapshot image data.
    var mapSnapshot: Data?

    // MARK: - Navigation / Direct References

    /// Optional parent Travel for direct access (alternative to itinerary lookup).
    var travel: Travel?

    /// Optional Day grouping inside a Travel.
    var itinerary: Itinerary?

    // MARK: - Sync Metadata

    /// Timestamp of last successful cloud sync.
    var lastSyncedAt: Date?
    /// Soft-delete flag for sync reconciliation.
    var isDeleted: Bool = false

    // MARK: - Init

    init(
        name: String,
        type: String = SpotType.sightseeing.rawValue,
        status: String = SpotStatus.wishing.rawValue,
        estimatedDate: Date? = nil,
        actualDate: Date? = nil,
        sequence: Int = 1,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type
        self.statusRaw = status
        self.estimatedDate = estimatedDate
        self.actualDate = actualDate
        self.sequence = sequence
        self.notes = notes
        self.photos = []
    }
}

// MARK: - Computed Business Proxies

extension Spot {

    /// Typed accessor for the visit category.
    var type: SpotType {
        get { SpotType(rawValue: typeRaw) ?? .sightseeing }
        set { typeRaw = newValue.rawValue }
    }

    /// Typed accessor for the visit lifecycle status.
    var status: SpotStatus {
        get { SpotStatus(rawValue: statusRaw) ?? .wishing }
        set { statusRaw = newValue.rawValue }
    }

    /// Projected `CLLocationCoordinate2D` from stored lat/lng.
    /// Returns `nil` when either coordinate is missing.
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Display Helpers

extension Spot {

    /// Whether this spot has been visited (status is `.travelled`).
    var isVisited: Bool {
        status == .travelled
    }

    /// Whether the spot has coordinates set.
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// Whether the spot has any photo content (local or remote).
    var hasPhotos: Bool {
        !photos.isEmpty || !photoPaths.isEmpty
    }

    /// Short description for list previews.
    var previewSubtitle: String {
        var parts = [type.displayName]
        if let address {
            parts.append(address)
        }
        return parts.joined(separator: " \u{00B7} ")
    }
}

// MARK: - SpotType

enum SpotType: String, CaseIterable, Codable {
    case food = "Food"
    case sightseeing = "Sightseeing"
    case shopping = "Shopping"
    case performance = "Performance"
    case fun = "Fun"
    case hotel = "Hotel"
    case travel = "Travel"

    /// SF Symbol name for display.
    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .sightseeing:   return "binoculars"
        case .shopping:      return "bag"
        case .performance:   return "music.note"
        case .fun:           return "star"
        case .hotel:         return "bed.double"
        case .travel:        return "car"
        }
    }

    /// Human-readable label.
    var displayName: String { rawValue }
}

// MARK: - SpotStatus

enum SpotStatus: String, CaseIterable, Codable {
    case wishing = "Wishing"
    case planning = "Planning"
    case traveling = "Traveling"
    case travelled = "Travelled"
    case cancelled = "Cancelled"

    /// SF Symbol for status indicators in lists.
    var icon: String {
        switch self {
        case .wishing:    return "heart"
        case .planning:   return "calendar"
        case .traveling:  return "location.fill"
        case .travelled:  return "checkmark.circle.fill"
        case .cancelled:  return "xmark.circle"
        }
    }
}

