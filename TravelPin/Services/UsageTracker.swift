import Foundation
import Combine
import Supabase

@MainActor
final class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    @Published var usageCount: Int = 0
    let freeTierLimit = 20

    private let defaults = UserDefaults.standard
    private static let usageCountKey = "ai_usage_count"

    private init() {
        usageCount = defaults.integer(forKey: Self.usageCountKey)
    }

    var hasFreeUsesRemaining: Bool {
        usageCount < freeTierLimit
    }

    var remainingFreeUses: Int {
        max(0, freeTierLimit - usageCount)
    }

    func incrementUsage() {
        usageCount += 1
        defaults.set(usageCount, forKey: Self.usageCountKey)
    }

    /// Sync usage count from server. Server is source of truth.
    func syncFromServer() async {
        do {
            let userId = try await SupabaseService.shared.getCurrentUserId()
            let client = SupabaseService.shared.client
            let response: [String: Int] = try await client
                .from("ai_usage")
                .select("count")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            if let count = response["count"] {
                usageCount = count
                defaults.set(count, forKey: Self.usageCountKey)
            }
        } catch {
            print("[UsageTracker] Sync failed: \(error.localizedDescription)")
        }
    }
}
