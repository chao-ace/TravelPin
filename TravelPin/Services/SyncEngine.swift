import Foundation
import SwiftData
import Supabase
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
        // TODO: Wire up Supabase Realtime v2 postgres change stream when sync is enabled.
        // Supabase Swift v2 API example (implement when ready):
        //
        // Task {
        //     let channel = supabase.client.channel("db-changes")
        //     let inserts = channel.postgresChange(InsertAction.self, schema: "public", table: "trips")
        //     await channel.subscribe()
        //     for await insert in inserts {
        //         print("Remote insert: \(insert)")
        //     }
        // }
        print("[SyncEngine] Remote listener not yet configured.")
    }

    // Silent Batch Sync for local-to-remote
    func pushLocalChanges(_ travel: Travel) {
        // If it's a soft-delete, tell Supabase to remove it
        if travel.isDeleted {
            Task {
                do {
                    try await supabase.deleteTrip(id: travel.id)
                    print("🗑️ [SyncEngine] Successfully deleted trip \(travel.name) from cloud.")
                } catch {
                    print("❌ [SyncEngine] Delete sync failed: \(error)")
                }
            }
            return
        }
        
        Task {
            do {
                try await supabase.syncTrip(travel)
                
                // Update local sync metadata
                await MainActor.run {
                    travel.lastSyncedAt = Date()
                }
                
                print("☁️ [SyncEngine] Successfully synced trip \(travel.name) to cloud.")
            } catch {
                print("❌ [SyncEngine] Batch sync failed: \(error)")
                // Note: We don't fatalError here, just keep it in 'unsynced' state for next retry
            }
        }
    }
    
    // Pull from cloud (e.g., on App start or Pull-to-Refresh)
    func fetchRemoteChanges(modelContext: ModelContext) async {
        print("📥 [SyncEngine] Remote pull not yet implemented (Requires DTO-to-Model mapping).")
    }
}
