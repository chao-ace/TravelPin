import Foundation
import SwiftData

// MARK: - Travel Model

/// The root entity for a trip. Owns itineraries, spots, and luggage items via cascade relationships.
/// SwiftData stores enum values as raw strings (`statusRaw`, `typeRaw`) for schema safety.
@Model
final class Travel {

    // MARK: Sync Metadata

    /// Timestamp of the last successful cloud sync. `nil` means never synced.
    var lastSyncedAt: Date?

    /// Soft-delete flag. SyncEngine checks this before pushing to Supabase.
    var isDeleted: Bool = false

    // MARK: Identity

    /// Stable unique identifier used as the primary key across devices and cloud.
    @Attribute(.unique) var id: UUID = UUID()

    /// User-facing trip name (e.g. "Paris Architecture Tour").
    var name: String = ""

    // MARK: Dates

    /// The departure date.
    var startDate: Date = Date()

    /// The return date. Defaults to 3 days after `startDate`.
    var endDate: Date = Date().addingTimeInterval(86400 * 3)

    // MARK: Status & Type (Raw Storage)

    /// Backing store for `TravelStatus`. Stored as String for SwiftData compatibility.
    var statusRaw: String = TravelStatus.wishing.rawValue

    /// Backing store for `TravelType`. Stored as String for SwiftData compatibility.
    var typeRaw: String = TravelType.tourism.rawValue

    // MARK: Collections

    /// Names of travel companions (freeform strings, not references).
    var companionNames: [String] = []

    // MARK: Relationships (Cascade Ownership)

    /// Day-by-day route segments. Each itinerary optionally groups spots via `Spot.itinerary`.
    @Relationship(deleteRule: .cascade)
    var itineraries: [Itinerary]

    /// All geo-tagged places visited or planned. Spots link back to `Travel` (required)
    /// and optionally to an `Itinerary` for day grouping.
    @Relationship(deleteRule: .cascade)
    var spots: [Spot]

    /// Packing checklist items for this trip.
    @Relationship(deleteRule: .cascade)
    var luggageItems: [LuggageItem]

    // MARK: Initializer

    init(
        name: String,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(86400 * 3),
        status: String = TravelStatus.wishing.rawValue,
        type: String = TravelType.tourism.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = status
        self.typeRaw = type
        self.itineraries = []
        self.spots = []
        self.luggageItems = []
    }
}

// MARK: - Typed Accessors & Computed Properties

extension Travel {

    /// The trip lifecycle status. Bridges the raw string to the typed enum.
    var status: TravelStatus {
        get { TravelStatus(rawValue: statusRaw) ?? .wishing }
        set { statusRaw = newValue.rawValue }
    }

    /// The trip category. Bridges the raw string to the typed enum.
    var type: TravelType {
        get { TravelType(rawValue: typeRaw) ?? .tourism }
        set { typeRaw = newValue.rawValue }
    }

    /// Total calendar days inclusive of start and end dates.
    /// Example: a Friday-to-Sunday trip returns 3.
    var durationDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return (components.day ?? 0) + 1
    }

    /// Whether the trip is in the future relative to now.
    var isUpcoming: Bool {
        startDate > Date()
    }

    /// Whether the trip is currently active (today falls within [startDate, endDate]).
    var isActive: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    /// Whether the trip has concluded.
    var isCompleted: Bool {
        Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: Date())
    }

    /// Number of spots that have been visited (status == .travelled).
    var visitedSpotCount: Int {
        spots.filter { $0.status == .travelled }.count
    }

    /// Number of checked luggage items out of the total.
    var checkedLuggageCount: Int {
        luggageItems.filter { $0.isChecked }.count
    }

    /// A formatted date-range string for display, e.g. "Apr 7 - Apr 10".
    var dateRangeString: String {
        "\(startDate.formatted(.dateTime.day().month())) - \(endDate.formatted(.dateTime.day().month().year()))"
    }
}

// MARK: - TravelStatus Enum

enum TravelStatus: String, CaseIterable, Codable {
    case wishing    = "Wishing"
    case planning   = "Planning"
    case traveling  = "Traveling"
    case travelled  = "Travelled"
    case cancelled  = "Cancelled"

    /// Localized display name, resolved via LanguageManager.
    var displayName: String {
        "status.\(self.rawValue.lowercased())".localized
    }

    /// SF Symbol icon for the status.
    var icon: String {
        switch self {
        case .wishing:    return "sparkles"
        case .planning:   return "pencil.and.list.clipboard"
        case .traveling:  return "airplane.departure"
        case .travelled:  return "checkmark.seal.fill"
        case .cancelled:  return "xmark.circle"
        }
    }
}

// MARK: - TravelType Enum

enum TravelType: String, CaseIterable, Codable {
    case tourism   = "Tourism"
    case concert   = "Concert"
    case chill     = "Chill"
    case business  = "Business"
    case other     = "Other"

    /// Localized display name, resolved via LanguageManager.
    var displayName: String {
        "type.\(self.rawValue.lowercased())".localized
    }

    /// SF Symbol icon for the travel type.
    var icon: String {
        switch self {
        case .tourism:   return "building.columns"
        case .concert:   return "music.note"
        case .chill:     return "sun.max"
        case .business:  return "briefcase"
        case .other:     return "globe"
        }
    }
}
