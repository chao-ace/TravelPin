import SwiftUI

/// Step 4: Preview summary before creating the travel.
struct WizardStepPreview: View {
    let name: String
    let selectedType: TravelType
    let startDate: Date
    let endDate: Date
    let budgetText: String
    let selectedCurrency: String
    let budgetBreakdown: [String: Double]

    private var totalBudget: Double { Double(budgetText) ?? 0 }
    private var durationDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: endDate))
        return (components.day ?? 0) + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text(locKey: "wizard.step4.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "wizard.step4.subtitle")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(.secondary)
            }

            // Summary card
            VStack(alignment: .leading, spacing: 20) {
                // Name & type
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TPDesign.celestialBlue.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: selectedType.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(TPDesign.celestialBlue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "wizard.step4.untitled".localized : name)
                            .font(TPDesign.bodyFont(18, weight: .bold))
                        Text(selectedType.displayName)
                            .font(TPDesign.captionFont())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Dates
                summaryRow(icon: "calendar", color: .tpAccent) {
                    Text("\(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.day().month().year()))")
                        .font(TPDesign.bodyFont())
                    Text(String(format: "wizard.step2.duration".localized, durationDays))
                        .font(TPDesign.captionFont())
                        .foregroundStyle(.secondary)
                }

                // Budget
                if totalBudget > 0 {
                    summaryRow(icon: "yensign.circle", color: TPDesign.warmGold) {
                        Text("\(selectedCurrency) \(String(format: "%.0f", totalBudget))")
                            .font(TPDesign.bodyFont())
                    }

                    // Budget breakdown preview
                    if !budgetBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(BudgetCategory.allCases.filter { budgetBreakdown[$0.rawValue] != nil }, id: \.self) { cat in
                                if let amount = budgetBreakdown[cat.rawValue] {
                                    HStack {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 14)
                                        Text(cat.displayName)
                                            .font(TPDesign.captionFont())
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.0f", amount))
                                            .font(TPDesign.captionFont())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 28)
                    }
                }
            }
            .padding(20)
            .background(TPDesign.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadowSmall()

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Label(locKey: "wizard.step4.tip1", systemImage: "lightbulb")
                    .font(TPDesign.captionFont())
                    .foregroundStyle(.secondary)
                Label(locKey: "wizard.step4.tip2", systemImage: "wand.and.stars.inverse")
                    .font(TPDesign.captionFont())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func summaryRow<Content: View>(icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
        }
    }
}
