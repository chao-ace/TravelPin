import Foundation
import SwiftData

// MARK: - PublishedTrip

/// A travel itinerary published to the community Inspiration Plaza.
/// Synced with Supabase for public discovery; cached locally for offline browsing.
@Model
final class PublishedTrip {

    @Attribute(.unique) var id: UUID = UUID()

    // MARK: Origin Reference

    /// The original Travel entity this was published from (nil for non-owner devices).
    var originalTravelId: UUID?

    // MARK: Author

    var authorName: String = ""
    var authorAvatarSymbol: String = "person.circle.fill"

    // MARK: Content

    var title: String = ""
    var descriptionText: String = ""
    var coverGradientRaw: String = "deepNavy"

    /// Semantic tags for category filtering (e.g. ["Nature", "Culture"]).
    var categoryTags: [String] = []

    /// The travel type raw value for card styling.
    var travelTypeRaw: String = TravelType.tourism.rawValue

    // MARK: Stats

    var likeCount: Int = 0
    var bookmarkCount: Int = 0
    var commentCount: Int = 0
    var viewCount: Int = 0
    var isFeatured: Bool = false

    // MARK: Timing

    var publishedAt: Date = Date()
    var durationDays: Int = 1

    // MARK: Itinerary Snapshot (JSON-encoded)

    /// Compact JSON representation of itineraries + spots for display without downloading full Travel.
    var snapshotJSON: Data?

    // MARK: Interactions (local cache)

    @Relationship(deleteRule: .cascade)
    var comments: [SocialInteraction]

    /// Whether the current user has liked this trip.
    var isLikedByCurrentUser: Bool = false
    /// Whether the current user has bookmarked this trip.
    var isBookmarkedByCurrentUser: Bool = false

    // MARK: Init

    init(
        originalTravelId: UUID?,
        authorName: String,
        title: String,
        descriptionText: String = "",
        coverGradientRaw: String = "deepNavy",
        categoryTags: [String] = [],
        travelTypeRaw: String = TravelType.tourism.rawValue,
        durationDays: Int = 1,
        snapshotJSON: Data? = nil
    ) {
        self.id = UUID()
        self.originalTravelId = originalTravelId
        self.authorName = authorName
        self.authorAvatarSymbol = "person.circle.fill"
        self.title = title
        self.descriptionText = descriptionText
        self.coverGradientRaw = coverGradientRaw
        self.categoryTags = categoryTags
        self.travelTypeRaw = travelTypeRaw
        self.durationDays = durationDays
        self.snapshotJSON = snapshotJSON
        self.comments = []
    }
}

// MARK: - Computed

extension PublishedTrip {

    var travelType: TravelType {
        TravelType(rawValue: travelTypeRaw) ?? .tourism
    }

    /// Decoded snapshot for display.
    var decodedSnapshot: TripSnapshot? {
        guard let data = snapshotJSON else { return nil }
        return try? JSONDecoder().decode(TripSnapshot.self, from: data)
    }
}

// MARK: - TripSnapshot (Lightweight display model)

struct TripSnapshot: Codable {
    var itineraries: [ItinerarySnapshot]
    var spots: [SpotSnapshot]
    var vibeTags: [String]
}

struct ItinerarySnapshot: Codable, Identifiable {
    var id = UUID()
    var day: Int
    var origin: String
    var destination: String
}

struct SpotSnapshot: Codable, Identifiable {
    var id = UUID()
    var name: String
    var typeRaw: String
    var notes: String
    var latitude: Double?
    var longitude: Double?
}
