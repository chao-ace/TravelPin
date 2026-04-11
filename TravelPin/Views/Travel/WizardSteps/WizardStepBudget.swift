import SwiftUI

/// Step 3: Budget input with smart category allocation.
struct WizardStepBudget: View {
    @Binding var budgetText: String
    @Binding var selectedCurrency: String
    @Binding var budgetBreakdown: [String: Double]
    let travelType: TravelType
    @State private var showBreakdown = false

    private var totalBudget: Double {
        Double(budgetText) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text(locKey: "wizard.step3.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "wizard.step3.subtitle")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(.secondary)
            }

            // Budget input
            CinematicFormSection(titleLocKey: "add.travel.budget") {
                VStack(spacing: 0) {
                    CinematicFormRow(icon: "yensign.circle", iconColor: TPDesign.warmGold) {
                        HStack(spacing: 8) {
                            TextField("add.travel.budget.placeholder".localized, text: $budgetText)
                                .font(TPDesign.bodyFont())
                                .keyboardType(.decimalPad)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(["CNY", "USD", "EUR", "JPY", "GBP"], id: \.self) { code in
                                        CinematicChipButton(
                                            title: code,
                                            icon: nil,
                                            isSelected: selectedCurrency == code
                                        ) {
                                            withAnimation(TPDesign.springDefault) {
                                                selectedCurrency = code
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Smart allocation
            if totalBudget > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(TPDesign.springDefault) {
                            if budgetBreakdown.isEmpty {
                                applySmartAllocation()
                            }
                            showBreakdown.toggle()
                        }
                        TPHaptic.selection()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars.inverse")
                                .foregroundStyle(Color.tpAccent)
                            Text(locKey: "wizard.step3.smart")
                                .font(TPDesign.bodyFont(14, weight: .bold))
                                .foregroundStyle(Color.tpAccent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.tpAccent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    if showBreakdown && !budgetBreakdown.isEmpty {
                        breakdownView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Budget warning
                let allocated = budgetBreakdown.values.reduce(0, +)
                if allocated > totalBudget && !budgetBreakdown.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(TPDesign.warmAmber)
                        Text(String(format: "wizard.step3.over_budget".localized, String(format: "%.0f", allocated - totalBudget)))
                            .font(TPDesign.captionFont())
                            .foregroundStyle(TPDesign.warmAmber)
                    }
                    .padding(.horizontal, 4)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var breakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BudgetCategory.allCases.map { $0 }, id: \.rawValue) { category in
                let amount = budgetBreakdown[category.rawValue] ?? 0
                if amount > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(category.displayName, systemImage: category.icon)
                                .font(TPDesign.bodyFont(13, weight: .medium))
                            Spacer()
                            Text(String(format: "%.0f", amount))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text("(\(Int((amount / totalBudget) * 100))%)")
                                .font(TPDesign.captionFont())
                                .foregroundStyle(.secondary)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(TPDesign.alabaster)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(TPDesign.accentGradient)
                                    .frame(width: geo.size.width * min(amount / totalBudget, 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(TPDesign.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func applySmartAllocation() {
        let ratios = BudgetCategory.defaultRatios(for: travelType)
        var newBreakdown: [String: Double] = [:]
        for (category, ratio) in ratios {
            newBreakdown[category.rawValue] = ratio * totalBudget
        }
        budgetBreakdown = newBreakdown
    }
}
