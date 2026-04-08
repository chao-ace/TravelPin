import Foundation
import SwiftData

// MARK: - CollaboratorProfile

/// A local cache entry for a collaboration partner.
@Model
final class CollaboratorProfile {

    @Attribute(.unique) var id: UUID = UUID()

    var displayName: String = ""
    var avatarSymbol: String = "person.circle.fill"
    var colorHex: String = "#00FFAB"
    var isOnline: Bool = false
    var lastSeenAt: Date?

    // MARK: Init

    init(
        displayName: String,
        avatarSymbol: String = "person.circle.fill",
        colorHex: String = "#00FFAB"
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.avatarSymbol = avatarSymbol
        self.colorHex = colorHex
    }
}
