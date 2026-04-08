import Foundation
import SwiftData

// MARK: - CollaborationInvite

/// An invitation to collaborate on a shared trip.
@Model
final class CollaborationInvite {

    @Attribute(.unique) var id: UUID = UUID()

    var tripId: UUID = UUID()
    var tripName: String = ""
    var inviterName: String = ""
    var inviteCode: String = ""
    var roleRaw: String = CollabRole.editor.rawValue
    var statusRaw: String = CollabInviteStatus.pending.rawValue
    var recipientId: String?
    var createdAt: Date = Date()
    var respondedAt: Date?

    // MARK: Init

    init(
        tripId: UUID,
        tripName: String,
        inviterName: String,
        inviteCode: String,
        role: CollabRole = .editor,
        recipientId: String? = nil
    ) {
        self.id = UUID()
        self.tripId = tripId
        self.tripName = tripName
        self.inviterName = inviterName
        self.inviteCode = inviteCode
        self.roleRaw = role.rawValue
        self.recipientId = recipientId
    }

    var role: CollabRole {
        CollabRole(rawValue: roleRaw) ?? .viewer
    }

    var status: CollabInviteStatus {
        CollabInviteStatus(rawValue: statusRaw) ?? .pending
    }
}

// MARK: - CollabRole

enum CollabRole: String, CaseIterable, Codable {
    case owner = "Owner"
    case editor = "Editor"
    case viewer = "Viewer"

    var displayName: String {
        switch self {
        case .owner:  return "创建者"
        case .editor: return "可编辑"
        case .viewer: return "仅查看"
        }
    }

    var icon: String {
        switch self {
        case .owner:  return "crown.fill"
        case .editor: return "pencil.circle.fill"
        case .viewer: return "eye.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .owner:  return "warmGold"
        case .editor: return "tpAccent"
        case .viewer: return "celestialBlue"
        }
    }
}

// MARK: - CollabInviteStatus

enum CollabInviteStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case expired = "Expired"
}
