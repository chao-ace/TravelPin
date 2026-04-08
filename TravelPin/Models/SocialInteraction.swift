import Foundation
import SwiftData

// MARK: - SocialInteraction

/// A user interaction with a published trip (like, bookmark, or comment).
@Model
final class SocialInteraction {

    @Attribute(.unique) var id: UUID = UUID()

    var publishedTripId: UUID = UUID()
    var userId: String = ""
    var typeRaw: String = SocialInteractionType.like.rawValue
    var content: String?
    var createdAt: Date = Date()

    // MARK: Author info (cached for display)

    var authorName: String = ""
    var authorAvatarSymbol: String = "person.circle.fill"

    // MARK: Init

    init(
        publishedTripId: UUID,
        userId: String,
        type: SocialInteractionType,
        content: String? = nil,
        authorName: String = "",
        authorAvatarSymbol: String = "person.circle.fill"
    ) {
        self.id = UUID()
        self.publishedTripId = publishedTripId
        self.userId = userId
        self.typeRaw = type.rawValue
        self.content = content
        self.createdAt = Date()
        self.authorName = authorName
        self.authorAvatarSymbol = authorAvatarSymbol
    }

    var type: SocialInteractionType {
        SocialInteractionType(rawValue: typeRaw) ?? .like
    }
}

// MARK: - SocialInteractionType

enum SocialInteractionType: String, CaseIterable, Codable {
    case like = "Like"
    case bookmark = "Bookmark"
    case comment = "Comment"
}
