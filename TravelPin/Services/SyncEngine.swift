import Foundation
import SwiftData
import Supabase
import Realtime
import Combine

class SyncEngine {
    static let shared = SyncEngine()
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // Background sync process
    func startSync(modelContext: ModelContext) {
        // 1. Listen for local changes (SwiftData doesn't have a direct Change Listener yet,
        // so we'll trigger sync on specific UI actions or a timer).
        
        // 2. Poll/Listen for remote changes via Supabase Realtime (Postgres Changes)
        setupRemoteListener(modelContext: modelContext)
    }
    
    private func setupRemoteListener(modelContext: ModelContext) {
        let channel = supabase.client.realtime.channel("public:trips")
        
        channel.on("postgres_changes", filter: .init(event: "INSERT", schema: "public", table: "trips")) { message in
            // Handle remote insert -> Save to SwiftData
            print("Remote Trip Inserted!")
        }
        
        Task {
            await channel.subscribe()
        }
    }
    
    // Silent Batch Sync for local-to-remote
    func pushLocalChanges(_ travel: Travel) {
        Task {
            do {
                try await supabase.syncTrip(travel)
                print("Successfully synced trip \(travel.name) to cloud.")
            } catch {
                print("Batch sync failed: \(error)")
                // Store in an 'Outbox' for retry later
            }
        }
    }
}
