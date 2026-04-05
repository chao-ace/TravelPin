import Foundation
import Supabase
import Realtime
import Combine

class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    private let client = SupabaseService.shared.client
    
    @Published var onlineUsers: [UUID: String] = [:] // ID to Name
    @Published var cursors: [UUID: [String: Double]] = [:] // UserID to Position
    
    private var channel: RealtimeChannelV2?
    
    private init() {}
    
    func joinTrip(tripID: UUID, userName: String) async {
        let channelName = "trip_\(tripID.uuidString)"
        channel = client.channel(channelName)
        
        // Presence: Track who is here
        _ = channel?.onPresenceChange { [weak self] _ in
            // Update onlineUsers based on the presence data
            // let state = self?.channel?.presenceState()
        }
        
        // Broadcasts: Receive cursor updates
        _ = channel?.onBroadcast(event: "cursor") { [weak self] message in
            // message is a [String: AnyJSON]
            if case let .string(userIDString) = message["user_id"],
               let userID = UUID(uuidString: userIDString),
               let xValue = message["x"],
               let yValue = message["y"] {
                
                // Extract double values safely
                let x: Double? = {
                    if case let .double(v) = xValue { return v }
                    if case let .integer(v) = xValue { return Double(v) }
                    return nil
                }()
                
                let y: Double? = {
                    if case let .double(v) = yValue { return v }
                    if case let .integer(v) = yValue { return Double(v) }
                    return nil
                }()
                
                if let x, let y {
                    DispatchQueue.main.async {
                        self?.cursors[userID] = ["x": x, "y": y]
                    }
                }
            }
        }
        
        await channel?.subscribe()
        
        // Initial Presence
        // try? await channel?.track(["name": .string(userName)])
    }
    
    func broadcastCursor(x: Double, y: Double, userID: UUID) {
        Task {
            try? await channel?.broadcast(
                event: "cursor",
                message: [
                    "user_id": .string(userID.uuidString),
                    "x": .double(x),
                    "y": .double(y)
                ]
            )
        }
    }
    
    func leaveTrip() {
        if let channel {
            Task {
                await client.removeChannel(channel)
            }
        }
    }
}
