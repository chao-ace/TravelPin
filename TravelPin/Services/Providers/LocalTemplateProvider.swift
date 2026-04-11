import Foundation

/// A local fallback provider that generates structured content
/// using the trip's metadata when the remote AI proxy is unavailable.
final class LocalTemplateProvider: AIProvider {
    let displayName = "TravelPin 智能模板"

    var isAvailable: Bool {
        get async { true }
    }

    func generate(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let response = generateResponse(for: prompt)

        return AsyncThrowingStream { continuation in
            let chars = Array(response)
            let chunkSize = max(1, chars.count / 60)
            var i = 0
            Task {
                while i < chars.count {
                    let end = min(i + chunkSize, chars.count)
                    continuation.yield(String(chars[i..<end]))
                    i = end
                    try? await Task.sleep(nanoseconds: 15_000_000)
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Response Generator

    private func generateResponse(for prompt: String) -> String {
        if prompt.contains("每日行程") || prompt.contains("行程建议") {
            return generateItineraryJSON(from: prompt)
        }
        if prompt.contains("行李") || prompt.contains("物品") || prompt.contains("packing" ) {
            return generatePackingJSON(from: prompt)
        }
        if prompt.contains("年度") || prompt.contains("回顾") {
            return generateAnnualReport(from: prompt)
        }
        // Default: journal
        return generateJournal(from: prompt)
    }

    // MARK: - Journal

    private func generateJournal(from prompt: String) -> String {
        let name = extractValue(key: "旅行名称", from: prompt) ?? "这段旅程"
        return """
        \(name)，不只是一段旅途，更是内心秩序的重建。

        漫步其间，每一个驻足的瞬间都像是一个停顿符，让我们在快节奏的生活中得以喘息。

        记录下的每一个坐标，无论是清晨的第一缕阳光，还是深夜街角微弱的灯火，都成为了生命架构中不可或缺的梁柱。

        铭刻每一个坐标，留住每一份感动。TravelPin 会一直陪伴着你，在未来的每一段旅程中，继续书写属于你的世界架构。
        """
    }

    // MARK: - Itinerary JSON

    private func generateItineraryJSON(from prompt: String) -> String {
        let name = extractValue(key: "旅行名称", from: prompt) ?? "梦想之旅"
        let days = extractDays(from: prompt)
        let type = extractValue(key: "旅行类型", from: prompt) ?? "观光"

        let dailySpots: [[String]] = [
            ["出发地机场", "当地特色餐厅", "城市地标景点", "文化博物馆", "日落观景台"],
            ["早餐咖啡馆", "历史古城区", "特色小吃街", "公园绿道", "夜市美食"],
            ["海边日出", "水上活动中心", "海鲜午餐", "当地市集", "篝火晚会"],
            ["山顶观景", "寺庙古迹", "当地午餐", "手工艺体验", "星空营地"],
            ["河畔晨跑", "艺术画廊", "米其林餐厅", "购物街区", "温泉放松"],
        ]

        let themes = ["初识\(name)", "深度探索", "自然风光", "人文之旅", "告别时光"]

        var result: [[String: Any]] = []
        for day in 1...days {
            let spotSet = dailySpots[(day - 1) % dailySpots.count]
            let daySpots = Array(spotSet.prefix(3 + (day % 2 == 0 ? 1 : 0)))
            let dict: [String: Any] = [
                "day": day,
                "origin": day == 1 ? "出发地" : "酒店",
                "destination": day == days ? "返程" : "酒店",
                "spots": daySpots,
                "theme": themes[(day - 1) % themes.count]
            ]
            result.append(dict)
        }

        if let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) {
            return String(data: data, encoding: .utf8) ?? "[]"
        }
        return "[]"
    }

    // MARK: - Packing JSON

    private func generatePackingJSON(from prompt: String) -> String {
        let items: [[String: String]] = [
            ["name": "轻便外套", "category": "Clothes", "reason": "应对早晚温差"],
            ["name": "舒适步行鞋", "category": "Clothes", "reason": "大量步行必备"],
            ["name": "充电宝", "category": "Electronics", "reason": "拍照导航耗电快"],
            ["name": "防晒霜", "category": "Essentials", "reason": "户外活动必备"],
            ["name": "便携水壶", "category": "Essentials", "reason": "随时补充水分"],
            ["name": "旅行收纳袋", "category": "Products", "reason": "整理行李更方便"],
            ["name": "常用药品", "category": "Essentials", "reason": "以备不时之需"],
        ]

        if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted) {
            return String(data: data, encoding: .utf8) ?? "[]"
        }
        return "[]"
    }

    // MARK: - Annual Report

    private func generateAnnualReport(from prompt: String) -> String {
        return """
        这一年，脚步丈量了远方，心灵找到了归途。

        从城市的霓虹到山野的星空，每一次出发都是对未知的拥抱，每一次归来都让家更有温度。

        年度关键词：探索、成长、自由。

        旅途中最珍贵的不是风景，而是那个在路上不断蜕变的自己。

        新的一年，愿你继续带着好奇心出发，去遇见更大的世界和更好的自己。
        """
    }

    // MARK: - Prompt Parsing Helpers

    private func extractValue(key: String, from prompt: String) -> String? {
        guard let range = prompt.range(of: key) else { return nil }
        let remainder = prompt[range.upperBound...]
        // Try "：value" format
        if let colonRange = remainder.range(of: "：") {
            let afterColon = remainder[colonRange.upperBound...]
            let lineEnd = afterColon.firstIndex(of: "\n") ?? afterColon.endIndex
            return String(afterColon[..<lineEnd]).trimmingCharacters(in: .whitespaces)
        }
        // Try ": value" format
        if let colonRange = remainder.range(of: ": ") {
            let afterColon = remainder[colonRange.upperBound...]
            let lineEnd = afterColon.firstIndex(of: "\n") ?? afterColon.endIndex
            return String(afterColon[..<lineEnd]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func extractDays(from prompt: String) -> Int {
        guard let range = prompt.range(of: "共 ") else { return 3 }
        let remainder = prompt[range.upperBound...]
        let digits = remainder.prefix(while: { $0.isNumber })
        return Int(digits) ?? 3
    }
}
