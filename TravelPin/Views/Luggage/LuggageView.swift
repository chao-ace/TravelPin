import SwiftUI
import SwiftData

struct LuggageView: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PackingTemplate.createdAt, order: .reverse) private var customTemplates: [PackingTemplate]
    @Query(sort: \Travel.startDate, order: .reverse) private var allTravels: [Travel]

    @State private var newItemName = ""
    @State private var selectedCategory = LuggageCategory.clothes
    
    // Management Sheets
    @State private var showingTemplateLibrary = false
    @State private var showingTripHistory = false
    @State private var showingSaveTemplateAlert = false
    @State private var newTemplateName = ""

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingSaveTemplateAlert = true }) {
                        Label("luggage.action.save_as_template".localized, systemImage: "plus.square.on.square")
                    }
                    .disabled(travel.luggageItems.isEmpty)
                    
                    Button(action: { showingTemplateLibrary = true }) {
                        Label("luggage.action.apply_template".localized, systemImage: "square.grid.2x2")
                    }
                    
                    Button(action: { showingTripHistory = true }) {
                        Label("luggage.action.copy_from_trip".localized, systemImage: "clock.arrow.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(TPDesign.obsidian)
                }
            }
        }
        .sheet(isPresented: $showingTemplateLibrary) {
            templateLibrarySheet
        }
        .sheet(isPresented: $showingTripHistory) {
            tripHistorySheet
        }
        .alert("luggage.action.save_as_template".localized, isPresented: $showingSaveTemplateAlert) {
            TextField("luggage.placeholder.template_name".localized, text: $newTemplateName)
            Button("common.cancel".localized, role: .cancel) { newTemplateName = "" }
            Button("common.confirm".localized) {
                saveAsTemplate()
            }
            .disabled(newTemplateName.isEmpty)
        }
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
            
            // Quick Add Templates (System Provided)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(systemTemplates(for: selectedCategory), id: \.self) { locKey in
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
                .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 1)
        )
        .shadowSmall()
        .cinematicFadeIn(delay: 0.1)
    }

    private var categoryGroups: some View {
        Group {
            let sortedCategories = LuggageCategory.allCases
            ForEach(sortedCategories, id: \.self) { category in
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
                    .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 1)
            )
            .shadowSmall()
        }
        .cinematicFadeIn(delay: 0.15)
    }

    // MARK: - Sheets

    private var templateLibrarySheet: some View {
        NavigationStack {
            List {
                if customTemplates.isEmpty {
                    ContentUnavailableView(
                        "luggage.empty.templates".localized,
                        systemImage: "square.grid.2x2",
                        description: Text("文档第06节建议建立模板复用")
                    )
                } else {
                    ForEach(customTemplates) { template in
                        Button {
                            applyTemplate(template)
                            showingTemplateLibrary = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(TPDesign.bodyFont(16, weight: .bold))
                                    .foregroundStyle(TPDesign.textPrimary)
                                Text("\(template.items.count) \("common.items".localized)")
                                    .font(TPDesign.captionFont())
                                    .foregroundStyle(TPDesign.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(template)
                            } label: {
                                Label("common.delete".localized, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("luggage.title.template_library".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.cancel".localized) { showingTemplateLibrary = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var tripHistorySheet: some View {
        NavigationStack {
            List {
                ForEach(allTravels.filter { $0.id != travel.id && !$0.luggageItems.isEmpty }) { historicalTravel in
                    Button {
                        copyFromTravel(historicalTravel)
                        showingTripHistory = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(historicalTravel.name)
                                .font(TPDesign.bodyFont(16, weight: .bold))
                                .foregroundStyle(TPDesign.textPrimary)
                            HStack {
                                Text(historicalTravel.startDate.formatted(.dateTime.year().month().day()))
                                Spacer()
                                Text("\(historicalTravel.luggageItems.count) \("common.items".localized)")
                            }
                            .font(TPDesign.captionFont())
                            .foregroundStyle(TPDesign.textTertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("luggage.title.trip_history".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.cancel".localized) { showingTripHistory = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Logic

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
    
    private func saveAsTemplate() {
        let template = PackingTemplate(name: newTemplateName)
        for item in travel.luggageItems {
            let tItem = TemplateItem(name: item.name, categoryRaw: item.categoryRaw, quantity: item.quantity, notes: item.notes)
            tItem.template = template
            template.items.append(tItem)
        }
        modelContext.insert(template)
        try? modelContext.save()
        newTemplateName = ""
        TPHaptic.notification(.success)
    }
    
    private func applyTemplate(_ template: PackingTemplate) {
        for tItem in template.items {
            let newItem = LuggageItem(name: tItem.name, categoryRaw: tItem.categoryRaw, quantity: tItem.quantity, notes: tItem.notes)
            newItem.travel = travel
            modelContext.insert(newItem)
        }
        try? modelContext.save()
        TPHaptic.notification(.success)
    }
    
    private func copyFromTravel(_ source: Travel) {
        for item in source.luggageItems {
            let newItem = LuggageItem(name: item.name, categoryRaw: item.categoryRaw, quantity: item.quantity, notes: item.notes)
            newItem.travel = travel
            modelContext.insert(newItem)
        }
        try? modelContext.save()
        TPHaptic.notification(.success)
    }
    
    private func systemTemplates(for category: LuggageCategory) -> [String] {
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
