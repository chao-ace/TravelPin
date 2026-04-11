import Foundation
import StoreKit
import Combine
import Supabase

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionStatus: Status = .free
    @Published var monthlyProduct: Product?
    @Published var yearlyProduct: Product?
    @Published var isLoading = false

    enum Status {
        case free
        case monthly
        case yearly
        case expired

        var isSubscribed: Bool { self == .monthly || self == .yearly }
    }

    static let monthlyProductID = "top.chaoace.travelpin.subscription.monthly"
    static let yearlyProductID = "top.chaoace.travelpin.subscription.yearly"

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var isSubscribed: Bool {
        subscriptionStatus.isSubscribed
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: [
                Self.monthlyProductID,
                Self.yearlyProductID
            ])
            for product in storeProducts {
                switch product.id {
                case Self.monthlyProductID: monthlyProduct = product
                case Self.yearlyProductID: yearlyProduct = product
                default: break
                }
            }
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkSubscriptionStatus()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Status Check

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.monthlyProductID ||
                  transaction.productID == Self.yearlyProductID else { continue }

            if transaction.expirationDate ?? .distantFuture > Date() {
                subscriptionStatus = transaction.productID == Self.monthlyProductID ? .monthly : .yearly
                syncToServer(transaction)
                return
            }
        }
        subscriptionStatus = .free
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.checkSubscriptionStatus()
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }

    private func syncToServer(_ transaction: StoreKit.Transaction) {
        Task {
            do {
                let userId = try await SupabaseService.shared.getCurrentUserId()
                let client = SupabaseService.shared.client
                try await client
                    .from("subscriptions")
                    .upsert([
                        "user_id": userId.uuidString,
                        "status": "active",
                        "product_id": transaction.productID,
                        "original_transaction_id": String(transaction.originalID),
                        "updated_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .execute()
            } catch {
                print("[SubscriptionManager] Server sync failed: \(error)")
            }
        }
    }

    /// Open App Store subscription management
    func manageSubscription() {
        Task {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await UIApplication.shared.open(url)
            }
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
