import SwiftUI
import SwiftData

struct LuggageView: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext

    @State private var newItemName = ""
    @State private var selectedCategory = LuggageCategory.clothes

    private var totalItems: Int {
        travel.luggageItems.count
    }

    private var checkedItems: Int {
        travel.luggageItems.filter { $0.isChecked }.count
    }

    private var packingProgress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(checkedItems) / Double(totalItems)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: TPDesign.spacing24) {
                progressHeader
                itemInputSection
                categoryGroups
                Spacer(minLength: TPDesign.spacing32)
            }
            .padding(.horizontal, TPDesign.spacing20)
            .padding(.top, TPDesign.spacing16)
        }
        .background(TPDesign.backgroundGradient)
        .navigationTitle("luggage.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        VStack(spacing: TPDesign.spacing12) {
            ProgressRingView(
                progress: packingProgress,
                lineWidth: 8,
                size: 88,
                ringColor: .tpAccent,
                showLabel: true,
                labelStyle: .fraction(filled: checkedItems, total: totalItems)
            )

            Text("detail.packing.prepared".localized)
                .font(TPDesign.captionFont())
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TPDesign.spacing8)
        .cinematicFadeIn(delay: 0)
    }

    private var itemInputSection: some View {
        VStack(spacing: TPDesign.spacing12) {
            HStack(spacing: TPDesign.spacing12) {
                CinematicTextField(
                    placeholderLocKey: "luggage.add.placeholder",
                    text: $newItemName
                )

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(newItemName.isEmpty ? TPDesign.textTertiary : Color.tpAccent)
                }
                .disabled(newItemName.isEmpty)
            }

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LuggageCategory.allCases, id: \.self) { cat in
                        CinematicChipButton(
                            title: cat.displayName,
                            icon: cat.icon,
                            isSelected: selectedCategory == cat
                        ) {
                            withAnimation(TPDesign.springDefault) {
                                selectedCategory = cat
                            }
                        }
                    }
                }
            }
            
            // Quick Add Templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates(for: selectedCategory), id: \.self) { locKey in
                        Button {
                            withAnimation(TPDesign.springDefault) {
                                let newItem = LuggageItem(name: locKey.localized, categoryRaw: selectedCategory.rawValue)
                                newItem.travel = travel
                                modelContext.insert(newItem)
                                try? modelContext.save()
                                TPHaptic.selection()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text(locKey.localized)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.tpAccent.opacity(0.08))
                            .foregroundStyle(Color.tpAccent)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.tpAccent.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(TPDesign.spacing16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .shadowSmall()
        .cinematicFadeIn(delay: 0.1)
    }

    private var categoryGroups: some View {
        Group {
            ForEach(LuggageCategory.allCases, id: \.self) { category in
                let items = travel.luggageItems.filter { $0.categoryRaw == category.rawValue }
                if !items.isEmpty {
                    luggageCategorySection(category: category, items: items)
                }
            }
        }
    }

    @ViewBuilder
    private func luggageCategorySection(category: LuggageCategory, items: [LuggageItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TPDesign.textTertiary)

                Text(category.displayName)
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(2)

                Text("(\(items.count))")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack(spacing: TPDesign.spacing12) {
                        Button {
                            withAnimation(TPDesign.springBouncy) {
                                item.isChecked.toggle()
                                try? modelContext.save()
                                TPHaptic.selection()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(item.isChecked ? Color.green : TPDesign.divider, lineWidth: 2)
                                    .frame(width: 24, height: 24)

                                if item.isChecked {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.green))
                                }
                            }
                            .animation(TPDesign.springBouncy, value: item.isChecked)
                        }
                        .buttonStyle(.plain)

                        Text(item.name)
                            .font(TPDesign.bodyFont())
                            .foregroundStyle(item.isChecked ? TPDesign.textTertiary : TPDesign.textPrimary)
                            .strikethrough(item.isChecked, color: TPDesign.textTertiary)

                        Spacer(minLength: 0)

                        Button {
                            withAnimation(TPDesign.springDefault) {
                                modelContext.delete(item)
                                try? modelContext.save()
                                TPHaptic.impact(.light)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.red.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if item.id != items.last?.id {
                        CinematicFormDivider()
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .shadowSmall()
        }
        .cinematicFadeIn(delay: 0.15)
    }

    private func addItem() {
        withAnimation(TPDesign.springDefault) {
            let newItem = LuggageItem(name: newItemName, categoryRaw: selectedCategory.rawValue)
            newItem.travel = travel
            modelContext.insert(newItem)
            try? modelContext.save()
            newItemName = ""
            TPHaptic.selection()
        }
    }
    
    private func templates(for category: LuggageCategory) -> [String] {
        switch category {
        case .clothes:
            return ["luggage.tpl.tshirt", "luggage.tpl.pants", "luggage.tpl.jacket", "luggage.tpl.underwear", "luggage.tpl.socks"]
        case .products:
            return ["luggage.tpl.toothbrush", "luggage.tpl.skincare", "luggage.tpl.shampoo", "luggage.tpl.towel", "luggage.tpl.cosmetics"]
        case .electronics:
            return ["luggage.tpl.charger", "luggage.tpl.powerbank", "luggage.tpl.earphones", "luggage.tpl.laptop", "luggage.tpl.adapter"]
        case .essentials:
            return ["luggage.tpl.passport", "luggage.tpl.card", "luggage.tpl.cash", "luggage.tpl.keys", "luggage.tpl.medicine"]
        case .other:
            return ["luggage.tpl.umbrella", "luggage.tpl.sunglasses", "luggage.tpl.bottle", "luggage.tpl.tissue"]
        }
    }
}
