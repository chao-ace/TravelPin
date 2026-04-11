import Foundation
import SwiftData

/// A single day plan within a Travel trip.
/// Owned by `Travel` via `Travel.itineraries` (cascade delete).
/// Spots are linked back through `Spot.itinerary` (no inverse collection here).
@Model
final class Itinerary {

    // MARK: - Identity

    @Attribute(.unique) var id: UUID = UUID()

    // MARK: - Schedule

    /// Which day of the trip (1-based index)
    var day: Int = 1

    // MARK: - Route

    /// Departure location name
    var origin: String = ""
    /// Arrival location name
    var destination: String = ""

    // MARK: - State

    /// Whether this day plan has been fully visited
    var isCompleted: Bool = false

    // MARK: - Sync Metadata

    /// Timestamp of last successful cloud sync
    var lastSyncedAt: Date?
    /// Soft-delete flag for sync reconciliation
    var isDeleted: Bool = false

    // MARK: - Relationship (Single Parent)

    /// The trip this day plan belongs to.
    /// Parent trip this daily plan belongs to.
    var travel: Travel?
    
    /// Spots assignment for this day.
    @Relationship(deleteRule: .nullify)
    var spots: [Spot] = []

    // MARK: - Init

    init(
        day: Int,
        origin: String,
        destination: String,
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.day = day
        self.origin = origin
        self.destination = destination
        self.isCompleted = isCompleted
        self.spots = []
    }
}

// MARK: - Display Helpers

extension Itinerary {

    /// Short label used in timeline headers, e.g. "D1"
    var dayLabel: String {
        "D\(day)"
    }

    /// Route summary, e.g. "Shinjuku -> Shibuya"
    var routeSummary: String {
        let o = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        if o.isEmpty && d.isEmpty {
            return ""
        }
        if o.isEmpty {
            return d
        }
        if d.isEmpty {
            return o
        }
        return "\(o) \u{2192} \(d)"
    }

    /// Whether the essential fields are filled in enough to be useful
    var isReady: Bool {
        !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

