import SwiftUI

/// Detailed budget breakdown view showing per-category allocation vs. actual spending.
struct BudgetBreakdownView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss

    private var totalBudget: Double { travel.budget ?? 0 }
    private var totalSpent: Double { travel.totalSpent }
    private var utilization: Double { totalBudget > 0 ? totalSpent / totalBudget : 0 }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Header card
                    budgetHeaderCard

                    // Budget warning
                    if utilization > 0.8 {
                        budgetWarning
                    }

                    // Category breakdown
                    if !travel.budgetBreakdown.isEmpty {
                        categoryBreakdownSection
                    }

                    // Spending by spot type
                    spendingByTypeSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(TPDesign.background)
            .navigationTitle(locKey: "budget.breakdown.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) { dismiss() }
                }
            }
        }
    }

    // MARK: - Header Card

    private var budgetHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locKey: "budget.breakdown.total")
                        .font(TPDesign.overline())
                        .foregroundStyle(.secondary)
                    Text(String(format: "\(travel.currency) %.0f", totalBudget))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(TPDesign.obsidian)
                }
                Spacer()
                // Usage ring
                ZStack {
                    ProgressRingView(
                        progress: min(utilization, 1.0),
                        lineWidth: 6,
                        size: 64,
                        showLabel: true,
                        labelStyle: .percentage
                    )
                    .environment(\.colorScheme, .light) // ensure consistent appearance
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TPDesign.alabaster)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(utilization > 1.0 ? AnyShapeStyle(TPDesign.leicaRed) : AnyShapeStyle(TPDesign.accentGradient))
                        .frame(width: geo.size.width * min(utilization, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(String(format: "budget.breakdown.spent".localized, String(format: "%.0f", totalSpent)))
                    .font(TPDesign.captionFont())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "budget.breakdown.remaining".localized, String(format: "%.0f", max(totalBudget - totalSpent, 0))))
                    .font(TPDesign.captionFont())
                    .foregroundStyle(totalSpent > totalBudget ? TPDesign.leicaRed : .green)
            }
        }
        .padding(20)
        .background(TPDesign.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadowSmall()
    }

    // MARK: - Budget Warning

    private var budgetWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(TPDesign.warmAmber)
            Text(utilization > 1.0
                 ? String(format: "budget.warning.over".localized, String(format: "%.0f", totalSpent - totalBudget))
                 : "budget.warning.near".localized)
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.warmAmber)
        }
        .padding(14)
        .background(TPDesign.warmAmber.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(locKey: "budget.breakdown.categories")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)

            ForEach(BudgetCategory.allCases, id: \.self) { category in
                if let allocated = travel.budgetBreakdown[category.rawValue] {
                    categoryRow(category: category, allocated: allocated)
                }
            }
        }
    }

    private func categoryRow(category: BudgetCategory, allocated: Double) -> some View {
        let spent = spendingForCategory(category)
        let ratio = allocated > 0 ? spent / allocated : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(category.displayName, systemImage: category.icon)
                    .font(TPDesign.bodyFont(14, weight: .semibold))
                Spacer()
                Text(String(format: "\(travel.currency)%.0f / %.0f", spent, allocated))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(ratio > 1 ? TPDesign.leicaRed : .secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Allocated background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(TPDesign.alabaster)
                        .frame(height: 6)
                    // Spent foreground
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ratio > 1 ? AnyShapeStyle(TPDesign.leicaRed) : AnyShapeStyle(TPDesign.accentGradient))
                        .frame(width: geo.size.width * min(ratio, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(TPDesign.secondaryBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Spending by Spot Type

    private var spendingByTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(locKey: "budget.breakdown.by_type")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)

            let typeSpending = Dictionary(grouping: travel.spots.filter { ($0.cost ?? 0) > 0 }) { $0.type }
                .mapValues { spots in spots.reduce(0.0) { $0 + ($1.cost ?? 0) } }
                .sorted { $0.value > $1.value }

            if typeSpending.isEmpty {
                Text(locKey: "budget.breakdown.no_spending")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(typeSpending, id: \.key) { type, amount in
                    HStack {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(type.displayName)
                            .font(TPDesign.bodyFont(14))
                        Spacer()
                        Text(String(format: "\(travel.currency)%.0f", amount))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private func spendingForCategory(_ category: BudgetCategory) -> Double {
        // Map spot types to budget categories for approximation
        switch category {
        case .transport:
            return travel.spots.filter { $0.type == .travel }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        case .food:
            return travel.spots.filter { $0.type == .food }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        case .tickets:
            return travel.spots.filter { $0.type == .sightseeing || $0.type == .performance }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        case .shopping:
            return travel.spots.filter { $0.type == .shopping }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        case .accommodation:
            return travel.spots.filter { $0.type == .hotel }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        case .other:
            return travel.spots.filter { $0.type == .fun }.reduce(0.0) { $0 + ($1.cost ?? 0) }
        }
    }
}
