import Foundation
import SwiftData
import Supabase
import Combine

// MARK: - CollaborationService

/// Manages trip collaboration: invites, role management, and shared editing.
@MainActor
class CollaborationService: ObservableObject {
    static let shared = CollaborationService()

    @Published var pendingInvites: [CollaborationInvite] = []
    @Published var activeCollaborations: [CollaborationInvite] = []
    @Published var isLoading = false

    private let client = SupabaseService.shared.client

    private init() {}

    // MARK: - Invite Generation

    func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    // MARK: - Create Invite

    func createInvite(tripId: UUID, tripName: String, role: CollabRole = .editor) async throws -> CollaborationInvite {
        let code = generateInviteCode()

        let invite = CollaborationInvite(
            tripId: tripId,
            tripName: tripName,
            inviterName: "Traveler",
            inviteCode: code,
            role: role
        )

        // Try to sync to Supabase, but don't block on failure
        Task {
            do {
                let userId = try await SupabaseService.shared.getCurrentUserId()
                let dto: [String: String] = [
                    "id": invite.id.uuidString,
                    "trip_id": tripId.uuidString,
                    "trip_name": tripName,
                    "inviter_id": userId.uuidString,
                    "inviter_name": invite.inviterName,
                    "invite_code": code,
                    "role": role.rawValue,
                    "status": "Pending"
                ]
                try await client.database.from("collaboration_invites").insert(dto).execute()
            } catch {
                print("[CollaborationService] Server sync failed, invite kept locally: \(error)")
            }
        }

        return invite
    }

    // MARK: - Accept Invite

    func acceptInvite(code: String, modelContext: ModelContext) async throws -> Travel? {
        let userId = try await SupabaseService.shared.getCurrentUserId()

        let invites: [CollaborationInviteRow] = try await client.database
            .from("collaboration_invites")
            .select()
            .eq("invite_code", value: code)
            .eq("status", value: "Pending")
            .execute()
            .value

        guard let inviteDTO = invites.first else {
            throw CollaborationError.invalidCode
        }

        let updateData: [String: String] = [
            "status": "Accepted",
            "recipient_id": userId.uuidString
        ]
        try await client.database
            .from("collaboration_invites")
            .update(updateData)
            .eq("id", value: inviteDTO.id.uuidString)
            .execute()

        let trips: [TravelDTO] = try await client.database
            .from("travels")
            .select()
            .eq("id", value: inviteDTO.tripId.uuidString)
            .execute()
            .value

        guard let travelDTO = trips.first else {
            throw CollaborationError.tripNotFound
        }

        let travel = Travel(
            name: travelDTO.name,
            startDate: travelDTO.start_date,
            endDate: travelDTO.end_date,
            status: travelDTO.status,
            type: travelDTO.type
        )
        travel.id = travelDTO.id
        travel.ownerId = travelDTO.user_id.uuidString
        travel.collaboratorIds.append(userId.uuidString)

        modelContext.insert(travel)
        try modelContext.save()

        return travel
    }

    // MARK: - Reject Invite

    func rejectInvite(code: String) async throws {
        let updateData: [String: String] = ["status": "Rejected"]
        try await client.database
            .from("collaboration_invites")
            .update(updateData)
            .eq("invite_code", value: code)
            .execute()
    }

    // MARK: - Fetch Invites

    func fetchPendingInvites() async {
        isLoading = true
        do {
            let dtos: [CollaborationInviteRow] = try await client.database
                .from("collaboration_invites")
                .select()
                .eq("status", value: "Pending")
                .execute()
                .value

            self.pendingInvites = dtos.map { dto in
                let invite = CollaborationInvite(
                    tripId: dto.tripId,
                    tripName: dto.tripName,
                    inviterName: dto.inviterName,
                    inviteCode: dto.inviteCode,
                    role: CollabRole(rawValue: dto.role) ?? .viewer
                )
                invite.id = dto.id
                invite.statusRaw = dto.status
                return invite
            }
        } catch {
            print("[CollaborationService] Fetch invites failed: \(error)")
        }
        isLoading = false
    }

    // MARK: - Remove Collaborator

    func removeCollaborator(tripId: UUID, userId: String) async throws {
        let updateData: [String: String] = ["status": "Rejected"]
        try await client.database
            .from("collaboration_invites")
            .update(updateData)
            .eq("trip_id", value: tripId.uuidString)
            .eq("recipient_id", value: userId)
            .execute()
    }

    // MARK: - Update Role

    func updateRole(tripId: UUID, userId: String, newRole: CollabRole) async throws {
        let updateData: [String: String] = ["role": newRole.rawValue]
        try await client.database
            .from("collaboration_invites")
            .update(updateData)
            .eq("trip_id", value: tripId.uuidString)
            .eq("recipient_id", value: userId)
            .execute()
    }
}

// MARK: - Errors

enum CollaborationError: LocalizedError {
    case invalidCode
    case tripNotFound
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .invalidCode:   return "邀请码无效或已过期"
        case .tripNotFound:  return "找不到对应的旅行"
        case .notAuthorized: return "您没有权限执行此操作"
        }
    }
}

// MARK: - Row DTOs

struct CollaborationInviteRow: Codable {
    let id: UUID
    let tripId: UUID
    let tripName: String
    let inviterId: String
    let inviterName: String
    let inviteCode: String
    let role: String
    let status: String
    let recipientId: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case tripName = "trip_name"
        case inviterId = "inviter_id"
        case inviterName = "inviter_name"
        case inviteCode = "invite_code"
        case role, status
        case recipientId = "recipient_id"
        case createdAt = "created_at"
    }
}
