import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @Query private var travels: [Travel]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var subscription = SubscriptionManager.shared
    @ObservedObject var usageTracker = UsageTracker.shared

    @State private var showFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - App Identity Header
                    appIdentityHeader

                    // MARK: - TravelPin AI Section
                    SettingsSection(title: "TravelPin AI") {
                        NavigationLink(destination: TravelPinAIView()) {
                            SettingsRow(
                                icon: "sparkles",
                                iconColor: .purple,
                                title: {
                                    if subscription.isSubscribed {
                                        return "TravelPin AI  PRO"
                                    }
                                    return "TravelPin AI"
                                }(),
                                subtitle: subscription.isSubscribed
                                    ? "已订阅 · 无限使用"
                                    : "已使用 \(usageTracker.usageCount)/\(usageTracker.freeTierLimit) 次"
                            )
                        }
                    }

                    // MARK: - User Context Section
                    SettingsSection(title: "settings.section.account".localized) {
                        NavigationLink(destination: ProfileView()) {
                            SettingsRow(
                                icon: "person.crop.circle.fill",
                                iconColor: .tpAccent,
                                title: "profile.user.name".localized,
                                subtitle: subscription.isSubscribed ? "Pro 会员" : "profile.user.role".localized
                            )
                        }
                        SettingsDivider()
                        ToggleRow(icon: "icloud.fill", iconColor: .blue, title: "settings.row.icloud".localized, isOn: $cloudSyncEnabled)
                            .onChange(of: cloudSyncEnabled) { _, newValue in
                                TPHaptic.selection()
                            }
                    }

                    // MARK: - Preferences Section
                    SettingsSection(title: "settings.section.preferences".localized) {
                        ToggleRow(
                            icon: "character.bubble.fill", 
                            iconColor: .orange, 
                            title: languageManager.currentLanguage == .english ? "English" : "简体中文", 
                            isOn: Binding(
                                get: { languageManager.currentLanguage == .english },
                                set: { languageManager.currentLanguage = $0 ? .english : .simplifiedChinese }
                            )
                        )
                        SettingsDivider()
                        NavigationLink(destination: AppIconSettingsView()) {
                            SettingsRow(icon: "app.dashed", iconColor: .tpAccent, title: "settings.row.app_icon".localized)
                        }
                        SettingsDivider()
                        ToggleRow(icon: "moon.fill", iconColor: .indigo, title: "settings.row.dark_mode".localized, isOn: $isDarkMode)
                        SettingsDivider()
                        ToggleRow(icon: "hand.tap.fill", iconColor: .pink, title: "settings.row.haptic".localized, isOn: $hapticEnabled)
                    }

                    // MARK: - Storage Section
                    SettingsSection(title: "settings.section.storage".localized) {
                        Button {
                            clearCache()
                        } label: {
                            SettingsRow(icon: "trash.fill", iconColor: .red, title: "settings.row.clear_cache".localized, subtitle: storageSummary)
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink(destination: DataManagementView()) {
                            SettingsRow(icon: "internaldrive.fill", iconColor: .gray, title: "settings.row.data_mgmt".localized, subtitle: "\("profile.stat.journeys".localized): \(travels.count)")
                        }
                    }

                    // MARK: - Support & Legal Section
                    SettingsSection(title: "settings.section.support".localized) {
                        Button {
                            requestReview()
                        } label: {
                            SettingsRow(icon: "star.fill", iconColor: .yellow, title: "settings.row.rate".localized)
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        Button {
                            showFeedback = true
                        } label: {
                            SettingsRow(icon: "envelope.fill", iconColor: .green, title: "settings.row.feedback".localized)
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink(destination: PrivacyPolicyView()) {
                            SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "settings.row.privacy".localized)
                        }
                        SettingsDivider()
                        NavigationLink(destination: TermsOfServiceView()) {
                            SettingsRow(icon: "doc.text.magnifyingglass", iconColor: .gray, title: "settings.row.terms".localized)
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
            .sheet(isPresented: $showFeedback) {
                FeedbackSheet()
            }
        }
    }

    private var storageSummary: String {
        let photoCount = travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
        if photoCount == 0 { return "settings.row.cache_calculating".localized }
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

                    Text("profile.user.name".localized)
                        .font(TPDesign.editorialSerif(24))
                        .foregroundStyle(TPDesign.obsidian)

                    Text("profile.user.tag".localized)
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(TPDesign.textTertiary)
                }
                .padding(.top, 20)

                // Stats Summary
                HStack(spacing: 0) {
                    profileStatItem(value: "\(travels.count)", label: "profile.stat.journeys".localized)
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(spots.count)", label: "profile.stat.spots".localized)
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(totalPhotos)", label: "profile.stat.photos".localized)
                    Divider().frame(height: 40)
                    profileStatItem(value: "\(visitedCities)", label: "profile.stat.cities".localized)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(TPDesign.secondaryBackground.opacity(0.8))
                        .shadowSmall()
                )

                // Achievement Badges
                VStack(alignment: .leading, spacing: 12) {
                    Text("profile.section.achievements".localized)
                        .font(TPDesign.editorialSerif(18))
                        .foregroundStyle(TPDesign.obsidian)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        achievementBadge(icon: "airplane", title: "profile.achievement.first".localized, earned: travels.count >= 1)
                        achievementBadge(icon: "globe.americas.fill", title: "profile.achievement.explorer".localized, earned: travels.count >= 5)
                        achievementBadge(icon: "camera.fill", title: "profile.achievement.photographer".localized, earned: totalPhotos >= 50)
                        achievementBadge(icon: "star.fill", title: "profile.achievement.ten_trips".localized, earned: travels.count >= 10)
                        achievementBadge(icon: "map.fill", title: "profile.achievement.footprints".localized, earned: visitedCities >= 10)
                        achievementBadge(icon: "wand.and.stars", title: "profile.achievement.ai".localized, earned: false)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(TPDesign.secondaryBackground.opacity(0.8))
                        .shadowSmall()
                )
            }
            .padding(.horizontal, 20)
        }
        .background(TPDesign.backgroundGradient.ignoresSafeArea())
        .navigationTitle("profile.title".localized)
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
                    .fill(earned ? Color.tpAccent.opacity(0.15) : TPDesign.secondaryBackground.opacity(0.3))
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
                .fill(isSelected ? Color.tpAccent.opacity(0.05) : TPDesign.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .fill(TPDesign.secondaryBackground)
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
                .fill(TPDesign.secondaryBackground.opacity(0.8))
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
            .background(TPDesign.secondaryBackground.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(TPDesign.obsidian.opacity(0.15), lineWidth: 0.5)
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

// MARK: - Feedback Sheet View

struct FeedbackSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var content: String = ""
    @State private var feedbackType: String = "feedback.type.bug".localized
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    let types = [
        "feedback.type.bug".localized,
        "feedback.type.feature".localized,
        "feedback.type.other".localized
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Type Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text(locKey: "feedback.type.label")
                        .font(TPDesign.overline())
                        .foregroundStyle(TPDesign.textTertiary)
                    
                    HStack(spacing: 12) {
                        ForEach(types, id: \.self) { type in
                            FeedbackTypeOption(
                                type: type,
                                isSelected: feedbackType == type,
                                action: { feedbackType = type }
                            )
                        }
                    }
                }
                .padding(.top, 10)
                
                // Content Input
                VStack(alignment: .leading, spacing: 12) {
                    Text(locKey: "feedback.content.label")
                        .font(TPDesign.overline())
                        .foregroundStyle(TPDesign.textTertiary)
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("feedback.placeholder".localized)
                                .font(TPDesign.bodyFont(15))
                                .foregroundStyle(TPDesign.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $content)
                            .font(TPDesign.bodyFont(15))
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(TPDesign.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(TPDesign.obsidian.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                    .frame(height: 200)
                }
                
                Spacer()
                
                // Submit Button
                Button {
                    submitFeedback()
                } label: {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("feedback.submit".localized)
                            .font(TPDesign.bodyFont(16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    if content.isEmpty {
                        Color.gray.opacity(0.3)
                    } else {
                        TPDesign.accentGradient
                    }
                }
                .clipShape(Capsule())
                .disabled(content.isEmpty || isSubmitting)
                .padding(.bottom, 10)
            }
            .padding(24)
            .navigationTitle("feedback.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .background(TPDesign.backgroundGradient)
            .alert("feedback.success".localized, isPresented: $showSuccess) {
                Button("common.done".localized) {
                    dismiss()
                }
            }
        }
    }
    
    private func submitFeedback() {
        isSubmitting = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            TPHaptic.notification(.success)
            showSuccess = true
        }
    }
}

// MARK: - Subviews for Feedback

struct FeedbackTypeOption: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            TPHaptic.selection()
            action()
        } label: {
            Text(type)
                .font(TPDesign.bodyFont(14, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? TPDesign.accentGradient : LinearGradient(colors: [TPDesign.secondaryBackground], startPoint: .top, endPoint: .bottom))
                .foregroundStyle(isSelected ? .white : TPDesign.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : TPDesign.obsidian.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
