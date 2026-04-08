import Foundation
import Supabase
import Combine

class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    private let client = SupabaseService.shared.client

    @Published var onlineUsers: [String: String] = [:]  // userId -> name
    @Published var collaborators: [CollaboratorProfile] = []
    @Published var activityLog: [ActivityEntry] = []
    @Published var isConnected: Bool = false

    private var channel: RealtimeChannelV2?

    private init() {}

    // MARK: - Join/Leave

    func joinTrip(tripID: UUID, userName: String) async {
        let channelName = "trip_\(tripID.uuidString)"
        channel = client.channel(channelName)

        // Broadcasts: Receive edit events
        _ = channel?.onBroadcast(event: "edit") { [weak self] message in
            DispatchQueue.main.async {
                self?.handleRemoteEdit(message)
            }
        }

        await channel?.subscribe()
        isConnected = true
    }

    // MARK: - Edit Broadcasting

    func broadcastEdit(event: String, entityType: String, entityName: String, userName: String) {
        Task {
            try? await channel?.broadcast(
                event: "edit",
                message: [
                    "event": .string(event),
                    "entity_type": .string(entityType),
                    "entity_name": .string(entityName),
                    "user_name": .string(userName),
                    "timestamp": .string(ISO8601DateFormatter().string(from: Date()))
                ]
            )
        }
    }

    // MARK: - Handle Remote Edits

    private func handleRemoteEdit(_ message: JSONObject) {
        guard case let .string(event) = message["event"],
              case let .string(entityType) = message["entity_type"],
              case let .string(entityName) = message["entity_name"] else { return }

        let userName: String = {
            if case let .string(name) = message["user_name"] { return name }
            return "Unknown"
        }()

        let entry = ActivityEntry(
            id: UUID(),
            userName: userName,
            event: event,
            entityType: entityType,
            entityName: entityName,
            timestamp: Date()
        )
        activityLog.insert(entry, at: 0)

        // Keep last 50 entries
        if activityLog.count > 50 {
            activityLog = Array(activityLog.prefix(50))
        }
    }

    func leaveTrip() {
        if let channel {
            Task {
                await client.removeChannel(channel)
            }
        }
        isConnected = false
        onlineUsers.removeAll()
    }
}

// MARK: - ActivityEntry

struct ActivityEntry: Identifiable {
    let id: UUID
    let userName: String
    let event: String
    let entityType: String
    let entityName: String
    let timestamp: Date

    var displayText: String {
        switch event {
        case "add":      return "\(userName) 添加了\(entityTypeDisplay)「\(entityName)」"
        case "edit":     return "\(userName) 编辑了\(entityTypeDisplay)「\(entityName)」"
        case "delete":   return "\(userName) 删除了\(entityTypeDisplay)「\(entityName)」"
        case "complete": return "\(userName) 完成了\(entityTypeDisplay)「\(entityName)」"
        default:         return "\(userName) 更新了\(entityTypeDisplay)「\(entityName)」"
        }
    }

    var entityTypeDisplay: String {
        switch entityType {
        case "spot":       return "景点"
        case "itinerary":  return "行程"
        case "luggage":    return "行李项"
        default:           return entityType
        }
    }

    var eventIcon: String {
        switch event {
        case "add":      return "plus.circle.fill"
        case "edit":     return "pencil.circle.fill"
        case "delete":   return "trash.circle.fill"
        case "complete": return "checkmark.circle.fill"
        default:         return "info.circle.fill"
        }
    }

    var eventColor: String {
        switch event {
        case "add":      return "tpAccent"
        case "edit":     return "celestialBlue"
        case "delete":   return "warmAmber"
        case "complete": return "tpAccent"
        default:         return "textTertiary"
        }
    }
}
