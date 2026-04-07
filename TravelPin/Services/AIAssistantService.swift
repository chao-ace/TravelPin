import Foundation
import Combine

@MainActor
class AIAssistantService: ObservableObject {
    static let shared = AIAssistantService()

    @Published var generatedText: String = ""
    @Published var isGenerating: Bool = false
    @Published var error: AIProviderError?

    private let registry = AIProviderRegistry.shared

    private init() {}

    enum WritingStyle: String, CaseIterable {
        case poetic = "Poetic & Emotional"
        case factual = "Factual & Informative"
        case casual = "Social Media Blogger"
        case quick = "Bullet Points"

        var displayName: String {
            switch self {
            case .poetic: return "文艺细腻"
            case .factual: return "纪实摘要"
            case .casual: return "社交博主"
            case .quick: return "要点速览"
            }
        }
    }

    // MARK: - Stream Generation

    func generateJournalStream(for travel: Travel, style: WritingStyle = .poetic) {
        guard !isGenerating else { return }

        let prompt = buildPrompt(for: travel, style: style)
        let provider = registry.activeProvider

        isGenerating = true
        generatedText = ""
        error = nil

        Task {
            do {
                var effectiveProvider = provider
                
                if await !effectiveProvider.isAvailable {
                    effectiveProvider = LocalTemplateProvider()
                }

                let stream = try await effectiveProvider.generate(prompt: prompt)
                for try await token in stream {
                    self.generatedText += token
                }
            } catch {
                self.error = .networkError(error.localizedDescription)
            }
            self.isGenerating = false
        }
    }

    // MARK: - Complete Generation (non-streaming)

    func generateJournalComplete(for travel: Travel, style: WritingStyle = .poetic) async throws -> String {
        let prompt = buildPrompt(for: travel, style: style)
        var effectiveProvider = registry.activeProvider
        
        if await !effectiveProvider.isAvailable {
            effectiveProvider = LocalTemplateProvider()
        }

        return try await effectiveProvider.generateComplete(prompt: prompt)
    }

    // MARK: - Prompt Builder

    private func buildPrompt(for travel: Travel, style: WritingStyle) -> String {
        let spotNames = travel.spots.map { "- \($0.name) (\($0.type.displayName))" }.joined(separator: "\n")
        let totalDays = travel.itineraries.count
        let dateRange = "\(formatDate(travel.startDate)) - \(formatDate(travel.endDate))"

        let spotDetails = travel.spots.prefix(10).map { spot in
            var detail = "- \(spot.name)"
            if !spot.notes.isEmpty { detail += "：\(spot.notes)" }
            if let rating = spot.rating { detail += "（评分：\(rating)/5）" }
            if let cost = spot.cost { detail += "（花费：¥\(Int(cost))）" }
            return detail
        }.joined(separator: "\n")

        switch style {
        case .poetic:
            return """
            你是一位才华横溢的旅行文学作家。请为以下旅行撰写一篇文艺细腻的旅行随笔。

            旅行名称：\(travel.name)
            时间：\(dateRange)
            共 \(totalDays) 天

            去过的景点：
            \(spotDetails.isEmpty ? spotNames : spotDetails)

            要求：
            1. 用文学的手法，捕捉旅途中的光影变幻、空气中流动的气味，以及在那一刻心底最柔软的触动
            2. 寻找这些景点之间无形的"主旋律"，形成连贯的叙事
            3. 字数 800-1200 字
            4. 语言优美但不矫揉造作，真实感是第一位的
            5. 请用中文撰写
            """

        case .factual:
            return """
            请为以下旅行生成一份结构化的旅行总结报告。

            旅行名称：\(travel.name)
            时间：\(dateRange)
            共 \(totalDays) 天
            旅行类型：\(travel.type.displayName)

            景点列表：
            \(spotDetails.isEmpty ? spotNames : spotDetails)

            请包含：
            1. 行程概览（总天数、景点数、城市）
            2. 每日行程回顾
            3. 亮点推荐 TOP 3
            4. 实用建议（交通、住宿、美食）
            5. 总花费估算（如有数据）

            用中文撰写，语气客观专业。
            """

        case .casual:
            return """
            你是一位很受欢迎的旅行生活方式博主。请为以下旅行写一篇社交媒体推文，适合发在小红书上。

            旅行名称：\(travel.name)
            时间：\(dateRange)

            打卡景点：
            \(spotDetails.isEmpty ? spotNames : spotDetails)

            要求：
            1. 用充满活力、有审美感、非常亲近读者的口吻
            2. 加入恰到好处的 Emoji 🌟✨📸
            3. 包含实用 tips（人均消费、最佳时间、避坑指南）
            4. 字数 300-500 字
            5. 适合小红书风格的排版（适当分段、标题醒目）
            6. 用中文撰写
            """

        case .quick:
            return """
            请用简洁的要点格式总结以下旅行：

            旅行名称：\(travel.name)
            时间：\(dateRange)
            共 \(totalDays) 天

            景点：
            \(spotDetails.isEmpty ? spotNames : spotDetails)

            输出格式：
            - 🗓 行程：X天，X个景点
            - 🌟 亮点：（3个最值得去的）
            - 💡 建议：（3条实用建议）
            - 💰 预算参考：（如有）

            用中文，简洁有力。
            """
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}
