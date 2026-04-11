import SwiftUI
import SwiftData

// MARK: - AI Copilot Sheet

struct AICopilotSheet: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var destination = ""
    @State private var season = ""
    @State private var tripStyle = ""
    @State private var additionalNotes = ""
    @State private var suggestions: [CopilotSuggestion] = []
    @State private var isGenerating = false
    @State private var selectedSuggestions: Set<UUID> = []

    private let seasons = ["春季", "夏季", "秋季", "冬季"]
    private let styles = ["观光", "商务", "休闲度假", "演唱会", "户外探险"]

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: TPDesign.spacing24) {
                        // Input section
                        inputSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Generate button
                        generateButton
                            .padding(.horizontal, 20)

                        // Results
                        if !suggestions.isEmpty {
                            resultsSection
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 60)
                    }
                }
            }
            .navigationTitle(locKey: "copilot.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !selectedSuggestions.isEmpty {
                        Button {
                            addSelectedItems()
                        } label: {
                            Text(String(format: "copilot.action.add_count".localized, selectedSuggestions.count))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            // Destination
            VStack(alignment: .leading, spacing: 8) {
                Label("copilot.field.destination".localized, systemImage: "mappin.circle")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)

                TextField(travel.spots.first?.address ?? "copilot.placeholder.destination".localized, text: $destination)
                    .textFieldStyle(.plain)
                    .font(TPDesign.bodyFont())
                    .padding(12)
                    .background(TPDesign.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusSmall))
            }

            // Season chips
            VStack(alignment: .leading, spacing: 8) {
                Label("copilot.field.season".localized, systemImage: "sun.max")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(seasons, id: \.self) { s in
                            CinematicChipButton(
                                title: s,
                                isSelected: season == s
                            ) {
                                withAnimation(TPDesign.springDefault) { season = s }
                            }
                        }
                    }
                }
            }

            // Trip style chips
            VStack(alignment: .leading, spacing: 8) {
                Label("copilot.field.style".localized, systemImage: "figure.walk")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(styles, id: \.self) { s in
                            CinematicChipButton(
                                title: s,
                                isSelected: tripStyle == s
                            ) {
                                withAnimation(TPDesign.springDefault) { tripStyle = s }
                            }
                        }
                    }
                }
            }

            // Additional notes
            VStack(alignment: .leading, spacing: 8) {
                Label("copilot.field.notes".localized, systemImage: "pencil")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)

                TextField("copilot.placeholder.notes".localized, text: $additionalNotes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(TPDesign.bodyFont(14))
                    .lineLimit(2...4)
                    .padding(12)
                    .background(TPDesign.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusSmall))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 1)
        )
        .shadowSmall()
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generateSuggestions()
        } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "copilot.generating".localized : "copilot.action.generate".localized)
            }
            .font(TPDesign.bodyFont(16, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                    .fill(TPDesign.brandGradient)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(format: "copilot.results.count".localized, suggestions.count))
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(1)

                Spacer()

                Button {
                    selectedSuggestions = Set(suggestions.map(\.id))
                } label: {
                    Text("copilot.action.select_all".localized)
                        .font(TPDesign.captionFont())
                        .foregroundStyle(Color.tpAccent)
                }
            }

            ForEach(suggestions) { suggestion in
                copilotSuggestionRow(suggestion)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TPDesign.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 1)
        )
        .shadowSmall()
    }

    private func copilotSuggestionRow(_ suggestion: CopilotSuggestion) -> some View {
        Button {
            withAnimation(TPDesign.springBouncy) {
                if selectedSuggestions.contains(suggestion.id) {
                    selectedSuggestions.remove(suggestion.id)
                } else {
                    selectedSuggestions.insert(suggestion.id)
                    TPHaptic.selection()
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedSuggestions.contains(suggestion.id) ? Color.tpAccent : TPDesign.divider, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if selectedSuggestions.contains(suggestion.id) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.tpAccent))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: categoryIcon(suggestion.category))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.tpAccent)

                        Text(suggestion.name)
                            .font(TPDesign.bodyFont(15, weight: .semibold))
                            .foregroundStyle(TPDesign.textPrimary)
                    }

                    if !suggestion.reason.isEmpty {
                        Text(suggestion.reason)
                            .font(TPDesign.bodyFont(12, weight: .regular))
                            .foregroundStyle(TPDesign.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func generateSuggestions() {
        isGenerating = true
        Task {
            // Combine weather-based hints with AI copilot logic
            let weatherHints = await IntelligenceService.shared.generateSmartPackingHints(for: travel)

            // Build context-aware suggestions
            var results: [CopilotSuggestion] = []

            // Weather-based items
            for hint in weatherHints {
                let existing = travel.luggageItems.contains { $0.name == hint }
                guard !existing else { continue }

                let category = inferCategory(from: hint)
                let reason = inferReason(from: hint, season: season, style: tripStyle)
                results.append(CopilotSuggestion(name: hint, category: category, reason: reason))
            }

            // Style-based items
            let styleItems = generateStyleItems(style: tripStyle, season: season)
            for item in styleItems {
                let existing = travel.luggageItems.contains { $0.name == item.name }
                guard !existing, !results.contains(where: { $0.name == item.name }) else { continue }
                results.append(item)
            }

            // Destination-specific items
            if !destination.isEmpty {
                let destItems = generateDestinationItems(destination: destination)
                for item in destItems {
                    let existing = travel.luggageItems.contains { $0.name == item.name }
                    guard !existing, !results.contains(where: { $0.name == item.name }) else { continue }
                    results.append(item)
                }
            }

            await MainActor.run {
                suggestions = results
                isGenerating = false
            }
        }
    }

    private func addSelectedItems() {
        for suggestion in suggestions where selectedSuggestions.contains(suggestion.id) {
            let newItem = LuggageItem(name: suggestion.name, categoryRaw: suggestion.category)
            newItem.travel = travel
            newItem.isAISuggested = true
            modelContext.insert(newItem)
        }
        try? modelContext.save()
        TPHaptic.notification(.success)
        dismiss()
    }

    // MARK: - Suggestion Helpers

    private func inferCategory(from name: String) -> String {
        let clothesKeywords = ["衣", "裤", "裙", "衫", "外套", "围巾", "内衣", "袜子", "夹克", "正装"]
        let electronicsKeywords = ["充电", "数据线", "耳机", "电脑", "适配", "电池"]
        let productsKeywords = ["防晒", "护肤", "洗", "牙", "化妆", "毛巾", "护发"]

        if clothesKeywords.contains(where: { name.contains($0) }) { return LuggageCategory.clothes.rawValue }
        if electronicsKeywords.contains(where: { name.contains($0) }) { return LuggageCategory.electronics.rawValue }
        if productsKeywords.contains(where: { name.contains($0) }) { return LuggageCategory.products.rawValue }
        return LuggageCategory.essentials.rawValue
    }

    private func inferReason(from name: String, season: String, style: String) -> String {
        if !season.isEmpty {
            return "\(season)出行推荐"
        }
        if name.contains("防晒") { return "防晒保护" }
        if name.contains("雨") { return "应对可能降雨" }
        if name.contains("充电") { return "保持设备电量充足" }
        return "旅行必备物品"
    }

    private func generateStyleItems(style: String, season: String) -> [CopilotSuggestion] {
        var items: [CopilotSuggestion] = []

        switch style {
        case "观光":
            items.append(contentsOf: [
                CopilotSuggestion(name: "舒适步行鞋", category: LuggageCategory.clothes.rawValue, reason: "观光需要大量步行"),
                CopilotSuggestion(name: "便携水壶", category: LuggageCategory.other.rawValue, reason: "保持水分补给"),
                CopilotSuggestion(name: "充电宝", category: LuggageCategory.electronics.rawValue, reason: "导航和拍照耗电快"),
            ])
        case "商务":
            items.append(contentsOf: [
                CopilotSuggestion(name: "正装", category: LuggageCategory.clothes.rawValue, reason: "商务场合需要"),
                CopilotSuggestion(name: "名片夹", category: LuggageCategory.essentials.rawValue, reason: "社交场合必备"),
                CopilotSuggestion(name: "笔记本电脑", category: LuggageCategory.electronics.rawValue, reason: "移动办公"),
            ])
        case "演唱会":
            items.append(contentsOf: [
                CopilotSuggestion(name: "降噪耳塞", category: LuggageCategory.other.rawValue, reason: "保护听力"),
                CopilotSuggestion(name: "充电宝", category: LuggageCategory.electronics.rawValue, reason: "拍照录像耗电快"),
                CopilotSuggestion(name: "荧光棒", category: LuggageCategory.other.rawValue, reason: "应援道具"),
            ])
        case "休闲度假":
            items.append(contentsOf: [
                CopilotSuggestion(name: "墨镜", category: LuggageCategory.other.rawValue, reason: "户外防晒"),
                CopilotSuggestion(name: "泳衣", category: LuggageCategory.clothes.rawValue, reason: "可能需要下水"),
                CopilotSuggestion(name: "防晒霜", category: LuggageCategory.products.rawValue, reason: "户外紫外线防护"),
            ])
        case "户外探险":
            items.append(contentsOf: [
                CopilotSuggestion(name: "登山鞋", category: LuggageCategory.clothes.rawValue, reason: "户外行走保护"),
                CopilotSuggestion(name: "急救包", category: LuggageCategory.essentials.rawValue, reason: "户外安全"),
                CopilotSuggestion(name: "防水袋", category: LuggageCategory.other.rawValue, reason: "保护电子设备"),
            ])
        default: break
        }

        // Season-specific additions
        switch season {
        case "冬季":
            items.append(CopilotSuggestion(name: "保暖手套", category: LuggageCategory.clothes.rawValue, reason: "冬季保暖"))
            items.append(CopilotSuggestion(name: "暖宝宝", category: LuggageCategory.other.rawValue, reason: "冬季取暖"))
        case "夏季":
            items.append(CopilotSuggestion(name: "遮阳帽", category: LuggageCategory.clothes.rawValue, reason: "防晒"))
            items.append(CopilotSuggestion(name: "防蚊液", category: LuggageCategory.products.rawValue, reason: "夏季防蚊"))
        default: break
        }

        return items
    }

    private func generateDestinationItems(destination: String) -> [CopilotSuggestion] {
        var items: [CopilotSuggestion] = []

        if destination.contains("海") || destination.contains("岛") || destination.contains("beach") {
            items.append(CopilotSuggestion(name: "防水手机袋", category: LuggageCategory.other.rawValue, reason: "海边防水保护"))
            items.append(CopilotSuggestion(name: "沙滩巾", category: LuggageCategory.clothes.rawValue, reason: "海滩休息"))
        }

        if destination.contains("山") || destination.contains("徒步") {
            items.append(CopilotSuggestion(name: "登山杖", category: LuggageCategory.other.rawValue, reason: "山地行走辅助"))
            items.append(CopilotSuggestion(name: "速干衣", category: LuggageCategory.clothes.rawValue, reason: "户外运动速干"))
        }

        if destination.contains("日本") || destination.contains("韩国") {
            items.append(CopilotSuggestion(name: "转换插头", category: LuggageCategory.electronics.rawValue, reason: "日韩电压不同"))
        }

        if destination.contains("欧洲") || destination.contains("欧洲") {
            items.append(CopilotSuggestion(name: "转换插头", category: LuggageCategory.electronics.rawValue, reason: "欧洲插座标准不同"))
            items.append(CopilotSuggestion(name: "防盗腰包", category: LuggageCategory.essentials.rawValue, reason: "旅游城市防盗"))
        }

        return items
    }

    private func categoryIcon(_ category: String) -> String {
        LuggageCategory(rawValue: category)?.icon ?? "bag"
    }
}

// MARK: - Copilot Suggestion Model

struct CopilotSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let reason: String
}
