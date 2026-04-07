import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @Query private var travels: [Travel]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - App Identity Header
                    appIdentityHeader

                    // MARK: - AI Provider Section
                    SettingsSection(title: "AI 智能助手") {
                        NavigationLink(destination: AIProviderSettingsView()) {
                            SettingsRow(
                                icon: "cpu",
                                iconColor: .purple,
                                title: "AI 模型配置",
                                subtitle: AIProviderRegistry.shared.activeProviderType.displayName
                            )
                        }
                    }

                    // MARK: - User Context Section
                    SettingsSection(title: "个人与账户") {
                        NavigationLink(destination: ProfileView()) {
                            SettingsRow(icon: "person.crop.circle.fill", iconColor: .tpAccent, title: "设计师 chao", subtitle: "普通用户")
                        }
                        SettingsDivider()
                        ToggleRow(icon: "icloud.fill", iconColor: .blue, title: "iCloud 云同步", isOn: $cloudSyncEnabled)
                            .onChange(of: cloudSyncEnabled) { _, newValue in
                                TPHaptic.selection()
                            }
                    }

                    // MARK: - Preferences Section
                    SettingsSection(title: "应用偏好") {
                        NavigationLink(destination: LanguageSettingsView()) {
                            SettingsRow(icon: "character.bubble.fill", iconColor: .orange, title: "语言设置", subtitle: languageManager.currentLanguage == .english ? "English" : "简体中文")
                        }
                        SettingsDivider()
                        NavigationLink(destination: AppIconSettingsView()) {
                            SettingsRow(icon: "app.dashed", iconColor: .tpAccent, title: "更换图标")
                        }
                        SettingsDivider()
                        ToggleRow(icon: "moon.fill", iconColor: .indigo, title: "深色模式", isOn: $isDarkMode)
                        SettingsDivider()
                        ToggleRow(icon: "hand.tap.fill", iconColor: .pink, title: "触感反馈", isOn: $hapticEnabled)
                    }

                    // MARK: - Storage Section
                    SettingsSection(title: "存储空间") {
                        Button {
                            clearCache()
                        } label: {
                            SettingsRow(icon: "trash.fill", iconColor: .red, title: "清除缓存", subtitle: storageSummary)
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink(destination: DataManagementView()) {
                            SettingsRow(icon: "internaldrive.fill", iconColor: .gray, title: "数据管理", subtitle: "\(travels.count) 个旅程")
                        }
                    }

                    // MARK: - Support & Legal Section
                    SettingsSection(title: "支持与关于") {
                        Button {
                            requestReview()
                        } label: {
                            SettingsRow(icon: "star.fill", iconColor: .yellow, title: "去 App Store 评分")
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        Button {
                            sendFeedback()
                        } label: {
                            SettingsRow(icon: "envelope.fill", iconColor: .green, title: "意见反馈")
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink(destination: PrivacyPolicyView()) {
                            SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "隐私政策")
                        }
                        SettingsDivider()
                        NavigationLink(destination: TermsOfServiceView()) {
                            SettingsRow(icon: "doc.text.magnifyingglass", iconColor: .gray, title: "使用条款")
                        }
                    }

                    // MARK: - Version Info
                    VStack(spacing: 8) {
                        Text("TravelPin for iOS")
                            .font(TPDesign.overline())
                            .foregroundStyle(TPDesign.textTertiary)
                        Text("Version 1.0.9 (Build 2026)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(TPDesign.backgroundGradient.ignoresSafeArea())
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var storageSummary: String {
        let photoCount = travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
        if photoCount == 0 { return "计算中..." }
        let estimatedMB = photoCount * 3 // rough estimate 3MB per photo
        if estimatedMB < 1024 { return "~\(estimatedMB) MB" }
        return String(format: "~%.1f GB", Double(estimatedMB) / 1024.0)
    }

    private var appIdentityHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(TPDesign.accentGradient)
                    .frame(width: 80, height: 80)
                    .shadowGlow(color: TPDesign.celestialBlue, radius: 15)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("TravelPin")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(TPDesign.obsidian)
                    .tracking(4)

                Text(locKey: "common.tagline")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TPDesign.textTertiary)
                    .tracking(2)
            }
        }
        .padding(.vertical, 32)
    }

    private func clearCache() {
        TPHaptic.notification(.success)
        let tempDir = FileManager.default.temporaryDirectory
        if let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    private func requestReview() {
        // Will use StoreKit review request in production
        if let url = URL(string: "https://apps.apple.com/app/id TravelPin") {
            UIApplication.shared.open(url)
        }
    }

    private func sendFeedback() {
        if let url = URL(string: "mailto:feedback@travelpin.app?subject=TravelPin Feedback") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Query private var travels: [Travel]
    @Query private var spots: [Spot]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar & Name
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(TPDesign.accentGradient)
                            .frame(width: 90, height: 90)
                            .shadowGlow(color: TPDesign.celestialBlue, radius: 15)

                        Image(systemName: "person.fill")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.white)
                    }

                    Text("设计师 chao")
                        .font(TPDesign.editorialSerif(24))
                        .foregroundStyle(TPDesign.obsidian)

                    Text("TravelPin 旅行家")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(TPDesign.textTertiary)
                }
                .padding(.top, 20)

                // Stats Summary
                HStack(spacing: 0) {
                    profileStatItem(value: "\(travels.count)", label: "旅程")
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(spots.count)", label: "足迹")
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(totalPhotos)", label: "照片")
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(visitedCities)", label: "城市")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .shadowSmall()
                )

                // Achievement Badges
                VStack(alignment: .leading, spacing: 12) {
                    Text("旅行成就")
                        .font(TPDesign.editorialSerif(18))
                        .foregroundStyle(TPDesign.obsidian)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        achievementBadge(icon: "airplane", title: "初次启程", earned: travels.count >= 1)
                        achievementBadge(icon: "globe.americas.fill", title: "世界探索者", earned: travels.count >= 5)
                        achievementBadge(icon: "camera.fill", title: "摄影达人", earned: totalPhotos >= 50)
                        achievementBadge(icon: "star.fill", title: "十旅达人", earned: travels.count >= 10)
                        achievementBadge(icon: "map.fill", title: "足迹遍布", earned: visitedCities >= 10)
                        achievementBadge(icon: "wand.and.stars", title: "AI 旅记家", earned: false)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .shadowSmall()
                )
            }
            .padding(.horizontal, 20)
        }
        .background(TPDesign.backgroundGradient.ignoresSafeArea())
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalPhotos: Int {
        travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
    }

    private var visitedCities: Int {
        let cities = Set(travels.flatMap { $0.spots.compactMap { $0.name.components(separatedBy: "·").first } })
        return cities.count
    }

    private func profileStatItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TPDesign.titleFont(20))
                .foregroundStyle(TPDesign.obsidian)
            Text(label)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func achievementBadge(icon: String, title: String, earned: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Color.tpAccent.opacity(0.15) : TPDesign.divider.opacity(0.3))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(earned ? Color.tpAccent : TPDesign.textTertiary)
            }
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(earned ? TPDesign.obsidian : TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - App Icon Settings

struct AppIconSettingsView: View {
    @State private var selectedIcon: String = "AppIcon"

    private let icons: [(name: String, title: String, subtitle: String)] = [
        ("AppIcon", "经典蓝", "默认品牌图标"),
        ("AppIcon_Dark", "深邃黑", "暗色系风格"),
        ("AppIcon_Sunset", "落日橘", "温暖旅程感"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            ForEach(icons, id: \.name) { icon in
                let isSelected = selectedIcon == icon.name
                Button {
                    TPHaptic.selection()
                    selectedIcon = icon.name
                } label: {
                    iconRow(icon: icon, isSelected: isSelected)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("更多图标即将推出")
                .font(TPDesign.bodyFont(13))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .padding(24)
        .navigationTitle("更换图标")
        .background(TPDesign.backgroundGradient)
    }

    private func iconRow(icon: (name: String, title: String, subtitle: String), isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(TPDesign.accentGradient)
                    .frame(width: 60, height: 60)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(icon.title)
                    .font(TPDesign.bodyFont(17, weight: .bold))
                    .foregroundStyle(TPDesign.obsidian)
                Text(icon.subtitle)
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textTertiary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.tpAccent)
                    .font(.title3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.tpAccent.opacity(0.05) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.tpAccent.opacity(0.3) : TPDesign.divider, lineWidth: 1)
                )
        )
    }
}

struct AIProviderSettingsView: View {
    @ObservedObject var registry = AIProviderRegistry.shared
    @State private var showAPIKeySuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Provider Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择 AI 模型")
                        .font(TPDesign.overline())
                        .foregroundStyle(TPDesign.textTertiary)
                        .padding(.leading, 4)

                    ForEach(AIProviderType.allCases, id: \.self) { type in
                        let isSelected = registry.activeProviderType == type
                        Button {
                            TPHaptic.selection()
                            registry.activeProviderType = type
                        } label: {
                            providerRow(type: type, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // API Key Input (shown for OpenAI / Anthropic)
                if registry.activeProviderType == .openAI || registry.activeProviderType == .anthropic {
                    apiKeySection
                }

                // Local template info
                if registry.activeProviderType == .localTemplate {
                    localTemplateInfo
                }

                // Foundation Models info
                if registry.activeProviderType == .foundationModels {
                    foundationModelsInfo
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .navigationTitle("AI 模型配置")
        .navigationBarTitleDisplayMode(.inline)
        .background(TPDesign.backgroundGradient)
        .alert("API Key 已保存", isPresented: $showAPIKeySuccess) {
            Button("好的") {}
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API 密钥")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.leading, 4)

            if registry.activeProviderType == .openAI {
                SecureField("sk-...", text: $registry.openAIKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, design: .monospaced))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(TPDesign.divider, lineWidth: 1))
                    )
                    .autocorrectionDisabled()
                    .autocapitalization(.none)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11))
                    Text("密钥仅存储在您的设备本地，不会上传至任何服务器")
                        .font(.system(size: 11))
                }
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.leading, 4)
            } else {
                SecureField("sk-ant-...", text: $registry.anthropicKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, design: .monospaced))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(TPDesign.divider, lineWidth: 1))
                    )
                    .autocorrectionDisabled()
                    .autocapitalization(.none)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11))
                    Text("密钥仅存储在您的设备本地，不会上传至任何服务器")
                        .font(.system(size: 11))
                }
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.leading, 4)
            }

            Button {
                TPHaptic.notification(.success)
                showAPIKeySuccess = true
            } label: {
                Label("验证并保存", systemImage: "checkmark.circle")
                    .font(TPDesign.bodyFont(15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TPDesign.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(CinematicButtonStyle())
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var localTemplateInfo: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(Color.tpAccent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能模板")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                    Text("无需联网，基于内置模板生成游记内容。适合离线使用场景。")
                        .font(TPDesign.bodyFont(13))
                        .foregroundStyle(TPDesign.textSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tpAccent.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tpAccent.opacity(0.15), lineWidth: 1))
            )
        }
    }

    private var foundationModelsInfo: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.title2)
                    .foregroundStyle(TPDesign.obsidian)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple 本地模型")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                    Text("使用设备端 AI 模型，数据完全在本地处理。需要 iOS 18.2 及以上版本。")
                        .font(TPDesign.bodyFont(13))
                        .foregroundStyle(TPDesign.textSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(TPDesign.obsidian.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(TPDesign.divider, lineWidth: 1))
            )
        }
    }

    private func providerIcon(for type: AIProviderType) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor(for: type).opacity(0.1))
                .frame(width: 40, height: 40)
            Image(systemName: iconSystemName(for: type))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor(for: type))
        }
    }

    private func iconColor(for type: AIProviderType) -> Color {
        switch type {
        case .foundationModels: return .black
        case .openAI: return .green
        case .anthropic: return .orange
        case .localTemplate: return Color.tpAccent
        }
    }

    private func iconSystemName(for type: AIProviderType) -> String {
        switch type {
        case .foundationModels: return "apple.logo"
        case .openAI: return "sparkles"
        case .anthropic: return "brain"
        case .localTemplate: return "doc.text.fill"
        }
    }

    private func providerDescription(for type: AIProviderType) -> String {
        switch type {
        case .foundationModels: return "Apple 设备端模型，隐私优先"
        case .openAI: return "GPT 系列，需要 API Key"
        case .anthropic: return "Claude 系列，需要 API Key"
        case .localTemplate: return "内置模板，无需联网"
        }
    }

    private func providerRow(type: AIProviderType, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            providerIcon(for: type)
            VStack(alignment: .leading, spacing: 3) {
                Text(type.displayName)
                    .font(TPDesign.bodyFont(16, weight: .bold))
                    .foregroundStyle(TPDesign.obsidian)
                Text(providerDescription(for: type))
                    .font(TPDesign.bodyFont(12))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.tpAccent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.tpAccent.opacity(0.06) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.tpAccent.opacity(0.3) : TPDesign.divider, lineWidth: 1)
                )
        )
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @Query private var travels: [Travel]
    @Query private var spots: [Spot]
    @Environment(\.modelContext) private var modelContext
    @State private var showExportSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dataSummaryCard
                exportSection
                dangerZone
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
        .background(TPDesign.backgroundGradient)
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("好的") {}
        } message: {
            Text("数据已复制到剪贴板")
        }
    }

    private var dataSummaryCard: some View {
        VStack(spacing: 16) {
            Text("数据概览")
                .font(TPDesign.editorialSerif(18))
                .foregroundStyle(TPDesign.obsidian)

            HStack(spacing: 0) {
                statCell(value: "\(travels.count)", label: "旅程")
                Divider().frame(height: 40)
                statCell(value: "\(spots.count)", label: "足迹")
                Divider().frame(height: 40)
                let photoCount = travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
                statCell(value: "\(photoCount)", label: "照片")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadowSmall()
        )
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(TPDesign.titleFont(18)).foregroundStyle(TPDesign.obsidian)
            Text(label).font(TPDesign.overline()).foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("导出与备份")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.leading, 4)

            Button {
                exportData()
            } label: {
                SettingsRow(icon: "square.and.arrow.up", iconColor: .blue, title: "导出数据为 JSON")
            }
            .buttonStyle(.plain)
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("危险操作")
                .font(TPDesign.overline())
                .foregroundStyle(.red)
                .padding(.leading, 4)

            Button(role: .destructive) {
                // Will add confirmation dialog
            } label: {
                SettingsRow(icon: "trash.fill", iconColor: .red, title: "清除所有数据")
            }
            .buttonStyle(.plain)
        }
    }

    private func exportData() {
        // Simple JSON export of travel data
        var exportDict: [[String: Any]] = []
        for travel in travels {
            exportDict.append([
                "name": travel.name,
                "startDate": travel.startDate.timeIntervalSince1970,
                "endDate": travel.endDate.timeIntervalSince1970,
                "status": travel.statusRaw,
                "type": travel.typeRaw,
                "spotCount": travel.spots.count,
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = string
            TPHaptic.notification(.success)
            showExportSuccess = true
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("隐私政策")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)

                Text("最后更新：2026年4月")
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textTertiary)

                policySection(title: "数据收集") {
                    Text("TravelPin 采用隐私优先的设计理念。您的旅行数据（包括照片、位置信息和行程安排）主要存储在您的设备本地。")
                }

                policySection(title: "iCloud 同步") {
                    Text("当您开启 iCloud 同步功能时，您的数据将通过 Apple 的加密通道存储在您的 iCloud 账户中。我们无法访问您的同步数据。")
                }

                policySection(title: "AI 功能") {
                    Text("AI 游记生成功能需要将您的旅行信息发送至您选择的 AI 服务提供商（OpenAI 或 Anthropic）。发送的数据仅包含旅行的文字描述，不包含照片。如果您选择本地模板或 Apple 基础模型，数据将完全在设备端处理。")
                }

                policySection(title: "位置信息") {
                    Text("TravelPin 使用设备的位置服务来辅助景点定位和地图展示。位置数据仅存储在您的设备上，不会分享给任何第三方。")
                }

                policySection(title: "地图数据") {
                    Text("离线地图瓦片来源于 OpenStreetMap 开源数据。缓存数据存储在应用沙盒中，可在设置中清除。")
                }

                policySection(title: "第三方服务") {
                    Text("本应用可能使用以下第三方服务：\n• OpenAI API（可选）\n• Anthropic API（可选）\n• Apple CloudKit\n• OpenStreetMap 瓦片服务")
                }

                policySection(title: "数据删除") {
                    Text("您可以随时在应用的「数据管理」中导出或删除所有数据。卸载应用将自动清除所有本地数据。")
                }

                policySection(title: "联系我们") {
                    Text("如有任何隐私相关问题，请发送邮件至 privacy@travelpin.app")
                }
            }
            .padding(24)
        }
        .background(TPDesign.backgroundGradient)
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TPDesign.bodyFont(16, weight: .bold))
                .foregroundStyle(TPDesign.obsidian)
            content()
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadowSmall()
        )
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("使用条款")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)

                Text("最后更新：2026年4月")
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textTertiary)

                termSection(title: "接受条款") {
                    Text("下载、安装或使用 TravelPin 应用，即表示您同意遵守本使用条款。如果您不同意这些条款，请不要使用本应用。")
                }

                termSection(title: "服务描述") {
                    Text("TravelPin 是一款旅行记录与管理工具，提供行程规划、足迹记录、AI 游记生成、离线地图和海报导出等功能。我们保留随时修改或中断服务的权利。")
                }

                termSection(title: "用户内容") {
                    Text("您保留对在 TravelPin 中创建的所有内容（旅行记录、照片、笔记等）的完全所有权。您对所创建内容的合法性和适当性负全部责任。")
                }

                termSection(title: "AI 生成内容") {
                    Text("AI 生成的游记内容仅供参考和娱乐目的。我们不保证 AI 生成内容的准确性、完整性和适用性。您应对 AI 生成内容的使用承担全部责任。")
                }

                termSection(title: "免责声明") {
                    Text("本应用按「现状」提供，不作任何明示或暗示的保证。在任何情况下，我们不对因使用本应用而产生的任何直接、间接、附带、特殊或后果性损害承担责任。")
                }

                termSection(title: "适用法律") {
                    Text("本条款受中华人民共和国法律管辖。任何争议应通过友好协商解决；协商不成的，应提交有管辖权的人民法院解决。")
                }
            }
            .padding(24)
        }
        .background(TPDesign.backgroundGradient)
        .navigationTitle("使用条款")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func termSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TPDesign.bodyFont(16, weight: .bold))
                .foregroundStyle(TPDesign.obsidian)
            content()
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadowSmall()
        )
    }
}

// MARK: - Shared Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(.white.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(TPDesign.bodyFont(16))
                .foregroundStyle(TPDesign.textPrimary)

            Spacer()

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(TPDesign.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 32, height: 32)

            Toggle(title, isOn: $isOn)
                .font(TPDesign.bodyFont(16))
                .foregroundStyle(TPDesign.textPrimary)
                .tint(.tpAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 64)
            .opacity(0.5)
    }
}

struct LanguageSettingsView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            languageOption(title: "English", sub: "English", lang: .english)
            languageOption(title: "简体中文", sub: "Simplified Chinese", lang: .simplifiedChinese)
            Spacer()
        }
        .padding(24)
        .navigationTitle("语言设置")
        .background(TPDesign.backgroundGradient)
    }

    func languageOption(title: String, sub: String, lang: AppLanguage) -> some View {
        Button {
            TPHaptic.selection()
            withAnimation {
                languageManager.currentLanguage = lang
                dismiss()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(TPDesign.bodyFont(17).bold())
                    Text(sub).font(TPDesign.captionFont()).foregroundStyle(.secondary)
                }
                Spacer()
                if languageManager.currentLanguage == lang {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.tpAccent)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
