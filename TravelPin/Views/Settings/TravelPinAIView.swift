import SwiftUI
import StoreKit

struct TravelPinAIView: View {
    @ObservedObject var usage = UsageTracker.shared
    @ObservedObject var subscription = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Hero Card
                heroCard

                // MARK: - Usage Status
                usageCard

                // MARK: - Subscription Options
                if subscription.isSubscribed {
                    activeSubscriptionCard
                } else {
                    subscriptionOptionsCard
                }

                // MARK: - Info
                infoCard
            }
            .padding(20)
        }
        .background(TPDesign.backgroundGradient)
        .navigationTitle("TravelPin AI")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscription.loadProducts()
            await usage.syncFromServer()
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(TPDesign.celestialBlue.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(TPDesign.celestialBlue)
            }

            Text("TravelPin AI")
                .font(TPDesign.editorialSerif(28))
                .foregroundStyle(TPDesign.obsidian)

            Text("powered by GLM-5.1")
                .font(TPDesign.captionFont())
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Usage

    private var usageCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("使用情况")
                    .font(TPDesign.bodyFont(16, weight: .bold))
                    .foregroundStyle(TPDesign.obsidian)
                Spacer()
                if subscription.isSubscribed {
                    Label("无限使用", systemImage: "infinity")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(.green)
                } else {
                    Text("已使用 \(usage.usageCount)/\(usage.freeTierLimit) 次")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(TPDesign.textSecondary)
                }
            }

            if !subscription.isSubscribed {
                ProgressView(value: Double(usage.usageCount), total: Double(usage.freeTierLimit))
                    .tint(usage.hasFreeUsesRemaining ? TPDesign.celestialBlue : TPDesign.leicaRed)
            }

            if !subscription.isSubscribed && !usage.hasFreeUsesRemaining {
                Text("免费次数已用完，订阅后可无限使用")
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.leicaRed)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1)
        )
        .overlay(RoundedRectangle(cornerRadius: TPDesign.radiusLarge).stroke(TPDesign.divider, lineWidth: 0.5))
    }

    // MARK: - Subscription Options

    private var subscriptionOptionsCard: some View {
        VStack(spacing: 16) {
            Text("解锁全部 AI 功能")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)

            // Monthly
            if let product = subscription.monthlyProduct {
                purchaseRow(
                    title: product.displayName,
                    subtitle: product.displayPrice + "/月",
                    price: product.displayPrice,
                    badge: nil,
                    isRecommended: false
                ) {
                    Task { _ = try? await subscription.purchase(product) }
                }
            } else {
                purchaseRow(
                    title: "月度会员",
                    subtitle: "¥12/月",
                    price: "¥12",
                    badge: nil,
                    isRecommended: false
                ) {
                    Task { await purchaseOrReload() }
                }
            }

            // Yearly
            if let product = subscription.yearlyProduct {
                purchaseRow(
                    title: product.displayName,
                    subtitle: product.displayPrice + "/年",
                    price: product.displayPrice,
                    badge: "省 ¥76",
                    isRecommended: true
                ) {
                    Task { _ = try? await subscription.purchase(product) }
                }
            } else {
                purchaseRow(
                    title: "年度会员",
                    subtitle: "¥68/年",
                    price: "¥68",
                    badge: "省 ¥76",
                    isRecommended: true
                ) {
                    Task { await purchaseOrReload() }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1)
        )
        .overlay(RoundedRectangle(cornerRadius: TPDesign.radiusLarge).stroke(TPDesign.divider, lineWidth: 0.5))
    }

    private func purchaseRow(title: String, subtitle: String, price: String, badge: String?, isRecommended: Bool, action: @escaping () -> Void) -> some View {
        Button {
            TPHaptic.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isRecommended ? TPDesign.celestialBlue.opacity(0.1) : TPDesign.surface1)
                        .frame(width: 44, height: 44)
                    Image(systemName: isRecommended ? "crown.fill" : "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isRecommended ? TPDesign.warmGold : TPDesign.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(TPDesign.bodyFont(15, weight: .bold))
                            .foregroundStyle(TPDesign.obsidian)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(TPDesign.warmAmber))
                        }
                    }
                    Text(subtitle)
                        .font(TPDesign.captionFont())
                        .foregroundStyle(TPDesign.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(price)
                    .font(TPDesign.bodyFont(16, weight: .bold))
                    .foregroundStyle(TPDesign.celestialBlue)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                    .fill(isRecommended ? TPDesign.celestialBlue.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                    .stroke(isRecommended ? TPDesign.celestialBlue.opacity(0.3) : TPDesign.divider, lineWidth: isRecommended ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Helper

    private func purchaseOrReload() async {
        if let product = subscription.yearlyProduct ?? subscription.monthlyProduct {
            _ = try? await subscription.purchase(product)
        } else {
            await subscription.loadProducts()
            ToastManager.shared.show(type: .warning, message: "正在连接 App Store，请稍后再试")
        }
    }

    // MARK: - Active Subscription

    private var activeSubscriptionCard: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("已订阅")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                        .foregroundStyle(TPDesign.obsidian)
                    Text(subscription.subscriptionStatus == .yearly ? "年度订阅" : "月度订阅")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(TPDesign.textSecondary)
                }

                Spacer()
            }

            Button {
                subscription.manageSubscription()
            } label: {
                Text("管理订阅")
                    .font(TPDesign.bodyFont(14, weight: .bold))
                    .foregroundStyle(TPDesign.celestialBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(TPDesign.celestialBlue.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1)
        )
        .overlay(RoundedRectangle(cornerRadius: TPDesign.radiusLarge).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI 日记、智能行程、行李建议等全部功能", systemImage: "text.badge.star")
            Label("由 GLM-5.1 模型提供支持", systemImage: "cpu")
            Label("请求经加密传输，内容不用于训练", systemImage: "lock.shield")
        }
        .font(TPDesign.bodyFont(13))
        .foregroundStyle(TPDesign.textSecondary)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(TPDesign.surface1.opacity(0.5))
        )
    }
}
