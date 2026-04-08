import Foundation
import SwiftData
import Supabase
import Combine

// MARK: - SocialService

/// Manages all social features: publishing trips, likes, bookmarks, comments.
@MainActor
class SocialService: ObservableObject {
    static let shared = SocialService()

    @Published var publicTrips: [PublishedTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client
    private var currentUserId: String = ""

    private init() {}

    // MARK: - Setup

    func ensureUserId() async throws -> String {
        if !currentUserId.isEmpty { return currentUserId }
        let uuid = try await SupabaseService.shared.getCurrentUserId()
        currentUserId = uuid.uuidString
        return currentUserId
    }

    // MARK: - Fetch Public Trips

    func fetchPublicTrips(category: String? = nil, refresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let _ = try await ensureUserId()

            var query = client.database
                .from("published_trips")
                .select()
                .order("published_at", ascending: false)
                .limit(30)

            if let category, category != "全部" {
                // Filter client-side since contains might not work
                _ = query
            }

            let response: [PublishedTripDTO] = try await query.execute().value

            let trips = response.compactMap { dto -> PublishedTrip? in
                let trip = PublishedTrip(
                    originalTravelId: dto.originalTravelId,
                    authorName: dto.authorName,
                    title: dto.title,
                    descriptionText: dto.descriptionText ?? "",
                    coverGradientRaw: dto.coverGradient ?? "deepNavy",
                    categoryTags: dto.categoryTags ?? [],
                    travelTypeRaw: dto.travelType ?? "Tourism",
                    durationDays: dto.durationDays ?? 1,
                    snapshotJSON: dto.snapshotJSON?.data(using: .utf8)
                )
                trip.id = dto.id
                trip.likeCount = dto.likeCount ?? 0
                trip.bookmarkCount = dto.bookmarkCount ?? 0
                trip.commentCount = dto.commentCount ?? 0
                trip.viewCount = dto.viewCount ?? 0
                trip.isFeatured = dto.isFeatured ?? false
                trip.publishedAt = dto.publishedAt ?? Date()
                trip.isLikedByCurrentUser = false
                trip.isBookmarkedByCurrentUser = false
                return trip
            }

            self.publicTrips = trips
        } catch {
            print("[SocialService] Fetch failed: \(error)")
            errorMessage = error.localizedDescription

            // Fallback to curated local data
            if publicTrips.isEmpty {
                loadFallbackData()
            }
        }

        isLoading = false
    }

    // MARK: - Publish

    func publishTrip(_ travel: Travel, title: String, description: String, categoryTags: [String]) async throws {
        let _ = try await ensureUserId()

        // Build snapshot
        let snapshot = TripSnapshot(
            itineraries: travel.itineraries.sorted { $0.day < $1.day }.map {
                ItinerarySnapshot(day: $0.day, origin: $0.origin, destination: $0.destination)
            },
            spots: travel.spots.map {
                SpotSnapshot(name: $0.name, typeRaw: $0.typeRaw, notes: $0.notes, latitude: $0.latitude, longitude: $0.longitude)
            },
            vibeTags: categoryTags
        )
        let snapshotData = try JSONEncoder().encode(snapshot)
        guard let snapshotString = String(data: snapshotData, encoding: .utf8) else {
            throw SocialError.encodingFailed
        }

        let dto = PublishedTripInsertDTO(
            originalTravelId: travel.id,
            authorId: currentUserId,
            authorName: "Traveler",
            title: title,
            descriptionText: description,
            coverGradient: coverGradient(for: travel.type),
            categoryTags: categoryTags,
            travelType: travel.typeRaw,
            durationDays: travel.durationDays,
            snapshotJSON: snapshotString
        )

        try await client.database.from("published_trips").insert(dto).execute()

        travel.isPublic = true
    }

    // MARK: - Interactions

    func toggleLike(_ trip: PublishedTrip) async {
        do {
            let _ = try await ensureUserId()
            if trip.isLikedByCurrentUser {
                try await client.database.from("social_interactions")
                    .delete()
                    .eq("published_trip_id", value: trip.id.uuidString)
                    .eq("user_id", value: currentUserId)
                    .eq("type", value: "Like")
                    .execute()
                trip.likeCount = max(0, trip.likeCount - 1)
            } else {
                let dto = SocialInteractionInsertDTO(
                    publishedTripId: trip.id,
                    userId: currentUserId,
                    type: "Like",
                    content: nil
                )
                try await client.database.from("social_interactions").insert(dto).execute()
                trip.likeCount += 1
            }
            trip.isLikedByCurrentUser.toggle()
        } catch {
            print("[SocialService] Like toggle failed: \(error)")
        }
    }

    func toggleBookmark(_ trip: PublishedTrip) async {
        do {
            let _ = try await ensureUserId()
            if trip.isBookmarkedByCurrentUser {
                try await client.database.from("social_interactions")
                    .delete()
                    .eq("published_trip_id", value: trip.id.uuidString)
                    .eq("user_id", value: currentUserId)
                    .eq("type", value: "Bookmark")
                    .execute()
                trip.bookmarkCount = max(0, trip.bookmarkCount - 1)
            } else {
                let dto = SocialInteractionInsertDTO(
                    publishedTripId: trip.id,
                    userId: currentUserId,
                    type: "Bookmark",
                    content: nil
                )
                try await client.database.from("social_interactions").insert(dto).execute()
                trip.bookmarkCount += 1
            }
            trip.isBookmarkedByCurrentUser.toggle()
        } catch {
            print("[SocialService] Bookmark toggle failed: \(error)")
        }
    }

    func postComment(_ trip: PublishedTrip, content: String) async throws {
        let _ = try await ensureUserId()
        let dto = SocialInteractionInsertDTO(
            publishedTripId: trip.id,
            userId: currentUserId,
            type: "Comment",
            content: content
        )
        try await client.database.from("social_interactions").insert(dto).execute()
        trip.commentCount += 1
    }

    func fetchComments(for tripId: UUID) async throws -> [SocialInteraction] {
        let response: PostgrestResponse<[SocialInteractionDTO]> = try await client.database
            .from("social_interactions")
            .select()
            .eq("published_trip_id", value: tripId.uuidString)
            .eq("type", value: "Comment")
            .order("created_at", ascending: true)
            .execute()

        return response.value.map { dto in
            SocialInteraction(
                publishedTripId: tripId,
                userId: dto.userId,
                type: .comment,
                content: dto.content,
                authorName: dto.authorName ?? "Traveler",
                authorAvatarSymbol: dto.authorAvatar ?? "person.circle.fill"
            )
        }
    }

    func incrementViewCount(_ trip: PublishedTrip) async {
        do {
            let newCount = trip.viewCount + 1
            let updateDict: [String: AnyJSON] = ["view_count": .integer(newCount)]
            try await client.database
                .from("published_trips")
                .update(updateDict)
                .eq("id", value: trip.id.uuidString)
                .execute()
            trip.viewCount = newCount
        } catch {
            print("[SocialService] View increment failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func coverGradient(for type: TravelType) -> String {
        switch type {
        case .tourism:  return "deepNavy"
        case .concert:  return "marineDeep"
        case .chill:    return "warmAmber"
        case .business: return "obsidian"
        case .other:    return "celestialBlue"
        }
    }

    private func loadFallbackData() {
        let fallback = [
            PublishedTrip(
                originalTravelId: nil,
                authorName: "Community",
                title: "Paris Architecture Tour",
                descriptionText: "A 5-day journey through the most iconic architectural landmarks in Paris.",
                coverGradientRaw: "deepNavy",
                categoryTags: ["Culture", "Architecture"],
                travelTypeRaw: "Tourism",
                durationDays: 5
            ),
            PublishedTrip(
                originalTravelId: nil,
                authorName: "Community",
                title: "Tokyo Cyberpunk Night",
                descriptionText: "3 nights exploring the neon-lit streets of Shinjuku and Shibuya.",
                coverGradientRaw: "marineDeep",
                categoryTags: ["Nightlife", "Food"],
                travelTypeRaw: "Chill",
                durationDays: 3
            ),
            PublishedTrip(
                originalTravelId: nil,
                authorName: "Community",
                title: "Kyoto Zen Gardens",
                descriptionText: "A peaceful 4-day retreat through ancient temples and gardens.",
                coverGradientRaw: "warmAmber",
                categoryTags: ["Nature", "Culture"],
                travelTypeRaw: "Tourism",
                durationDays: 4
            )
        ]
        // Mark first as featured
        if let first = fallback.first {
            first.isFeatured = true
        }
        self.publicTrips = fallback
    }
}

// MARK: - Errors

enum SocialError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "数据编码失败"
        }
    }
}

// MARK: - DTOs

struct PublishedTripDTO: Codable {
    let id: UUID
    let originalTravelId: UUID?
    let authorId: String?
    let authorName: String
    let title: String
    let descriptionText: String?
    let coverGradient: String?
    let categoryTags: [String]?
    let travelType: String?
    let durationDays: Int?
    let likeCount: Int?
    let bookmarkCount: Int?
    let commentCount: Int?
    let viewCount: Int?
    let isFeatured: Bool?
    let publishedAt: Date?
    let snapshotJSON: String?

    enum CodingKeys: String, CodingKey {
        case id
        case originalTravelId = "original_travel_id"
        case authorId = "author_id"
        case authorName = "author_name"
        case title
        case descriptionText = "description_text"
        case coverGradient = "cover_gradient"
        case categoryTags = "category_tags"
        case travelType = "travel_type"
        case durationDays = "duration_days"
        case likeCount = "like_count"
        case bookmarkCount = "bookmark_count"
        case commentCount = "comment_count"
        case viewCount = "view_count"
        case isFeatured = "is_featured"
        case publishedAt = "published_at"
        case snapshotJSON = "snapshot_json"
    }
}

struct PublishedTripInsertDTO: Codable {
    let originalTravelId: UUID
    let authorId: String
    let authorName: String
    let title: String
    let descriptionText: String
    let coverGradient: String
    let categoryTags: [String]
    let travelType: String
    let durationDays: Int
    let snapshotJSON: String?

    enum CodingKeys: String, CodingKey {
        case originalTravelId = "original_travel_id"
        case authorId = "author_id"
        case authorName = "author_name"
        case title
        case descriptionText = "description_text"
        case coverGradient = "cover_gradient"
        case categoryTags = "category_tags"
        case travelType = "travel_type"
        case durationDays = "duration_days"
        case snapshotJSON = "snapshot_json"
    }
}

struct SocialInteractionInsertDTO: Codable {
    let publishedTripId: UUID
    let userId: String
    let type: String
    let content: String?

    enum CodingKeys: String, CodingKey {
        case publishedTripId = "published_trip_id"
        case userId = "user_id"
        case type, content
    }
}

struct SocialInteractionDTO: Codable {
    let id: UUID
    let publishedTripId: UUID
    let userId: String
    let type: String
    let content: String?
    let authorName: String?
    let authorAvatar: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case publishedTripId = "published_trip_id"
        case userId = "user_id"
        case type, content
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case createdAt = "created_at"
    }
}
