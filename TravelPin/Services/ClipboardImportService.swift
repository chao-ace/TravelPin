import Foundation
import UIKit

// MARK: - Clipboard Import Service

/// Parses travel content from clipboard (e.g. 小红书 posts) into structured Spot suggestions.
final class ClipboardImportService {
    static let shared = ClipboardImportService()

    private init() {}

    // MARK: - Main Parse

    /// Read clipboard and attempt to parse travel-related content into spot suggestions.
    func parseClipboard() -> ClipboardImportResult? {
        guard UIPasteboard.general.hasStrings,
              let text = UIPasteboard.general.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Quick check: does it look like travel content?
        guard looksLikeTravelContent(trimmed) else { return nil }

        let spots = extractSpots(from: trimmed)
        guard !spots.isEmpty else { return nil }

        let dates = extractDates(from: trimmed)
        let budget = extractBudget(from: trimmed)

        return ClipboardImportResult(
            rawText: trimmed,
            suggestedSpots: spots,
            suggestedDates: dates,
            suggestedBudget: budget
        )
    }

    // MARK: - Content Detection

    private func looksLikeTravelContent(_ text: String) -> Bool {
        let travelKeywords = [
            "攻略", "行程", "推荐", "打卡", "景点", "必去", "旅行", "旅游", "自由行",
            "美食", "购物", "住宿", "酒店", "交通", "路线", "天行程", "日游",
            "机场", "高铁", "地铁", "门票", "网红", "隐藏", "宝藏",
            "restaurant", "attraction", "hotel", "travel", "itinerary",
            "must visit", "hidden gem", "攻略", "拍照", "出片"
        ]
        return travelKeywords.contains { text.contains($0) }
    }

    // MARK: - Spot Extraction

    private func extractSpots(from text: String) -> [ImportedSpot] {
        var spots: [ImportedSpot] = []
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 2 && trimmed.count <= 80 else { continue }

            // Skip lines that are clearly not spot names
            if isSkippableLine(trimmed) { continue }

            // Pattern: emoji + name (小红书 style)
            if let spot = parseEmojiPrefixedLine(trimmed) {
                spots.append(spot)
                continue
            }

            // Pattern: numbered list (1. / ① / Day1)
            if let spot = parseNumberedLine(trimmed) {
                spots.append(spot)
                continue
            }

            // Pattern: location markers (📍 / 🗺️ / #地点)
            if let spot = parseLocationMarkerLine(trimmed) {
                spots.append(spot)
                continue
            }

            // Pattern: "XX - description" or "XX｜description"
            if let spot = parseDashSeparatedLine(trimmed) {
                spots.append(spot)
                continue
            }
        }

        // Deduplicate by name
        var seen = Set<String>()
        return spots.filter { spot in
            let key = spot.name.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Line Parsers

    private func parseEmojiPrefixedLine(_ line: String) -> ImportedSpot? {
        // Match lines starting with common travel emojis followed by a name
        let emojiPattern = "^[🏯⛩️🏖️🌊🏔️⛩🎢🎡🎭🕌教堂⛪🏰🗼🗻🌋⛩🏖️🌊🏔️🎡🎭🕌🏰🗼⛲🏛️🎡🎯🎨🎬🎵🎪🎠🎪🎡🏟️⛳⛷️🏄🏊🚣🧗🚴🚵🏇⛹️🏋️🤸🤼🤽🤾🤺🎯⛳🎿🏂🏄🚣🏊🤽🧗🚵🏋️🤼🤺🤾].*"
        // Simpler approach: check if line starts with emoji
        let scalars = line.unicodeScalars
        guard let first = scalars.first, first.properties.isEmoji else { return nil }

        let name = line.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^[\\p{So}\\p{Sc}\\s]+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        guard name.count >= 2 else { return nil }
        return ImportedSpot(name: name, type: guessSpotType(from: line), source: .emoji)
    }

    private func parseNumberedLine(_ line: String) -> ImportedSpot? {
        // Match: 1. / 1、/ ① / Day1 / D1 / #1 etc.
        let patterns = [
            "^\\d+[.、)）]\\s*(.+)",
            "^[①②③④⑤⑥⑦⑧⑨⑩]\\s*(.+)",
            "^[Dd]ay\\s*\\d+[:\\s]+(.+)",
            "^[Dd]\\d+[:\\s]+(.+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let nameRange = Range(match.range(at: 1), in: line) {
                let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
                if name.count >= 2 {
                    return ImportedSpot(name: cleanSpotName(name), type: guessSpotType(from: name), source: .numbered)
                }
            }
        }

        return nil
    }

    private func parseLocationMarkerLine(_ line: String) -> ImportedSpot? {
        let markers = ["📍", "🗺️", "📌", "#"]
        for marker in markers {
            if line.contains(marker) {
                let name = line.components(separatedBy: marker)
                    .last?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                if name.count >= 2 {
                    return ImportedSpot(name: cleanSpotName(name), type: guessSpotType(from: line), source: .marker)
                }
            }
        }
        return nil
    }

    private func parseDashSeparatedLine(_ line: String) -> ImportedSpot? {
        let separators = [" - ", " — ", "｜", " | ", "·"]
        for sep in separators {
            if let range = line.range(of: sep) {
                let name = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if name.count >= 2 && name.count <= 20 {
                    let desc = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    return ImportedSpot(name: name, type: guessSpotType(from: line), notes: desc, source: .dash)
                }
            }
        }
        return nil
    }

    // MARK: - Date Extraction

    private func extractDates(from text: String) -> (start: Date?, end: Date?) {
        // Try to find date patterns like "2025.03.15-03.20" or "3月15日-3月20日"
        let patterns = [
            "(\\d{4})[./年](\\d{1,2})[./月](\\d{1,2})[日号]?\\s*[-–—~至到]\\s*(\\d{1,2})[./月](\\d{1,2})[日号]?",
            "(\\d{1,2})月(\\d{1,2})[日号]?\\s*[-–—~至到]\\s*(\\d{1,2})月(\\d{1,2})[日号]?",
            "Day\\s*\\d+\\s*[-–—~]\\s*Day\\s*\\d+"
        ]

        // Simplified: return nil for now, can be enhanced later
        return (nil, nil)
    }

    // MARK: - Budget Extraction

    private func extractBudget(from text: String) -> Double? {
        let patterns = [
            "预算[：:￥¥$]?\\s*(\\d+)",
            "(\\d+)[元块钱]",
            "[￥¥$]\\s*(\\d+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let value = Double(String(text[range])) {
                return value
            }
        }
        return nil
    }

    // MARK: - Helpers

    private func isSkippableLine(_ line: String) -> Bool {
        let skipPatterns = [
            "^#{1,6}\\s",  // markdown headers
            "^\\*{2,}",    // horizontal rules
            "^@",
            "^http",
            "^https",
            "关注", "点赞", "收藏", "转发", "评论",
            "小红书", "著作权", "原创", "侵权"
        ]
        return skipPatterns.contains { pattern in
            line.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func guessSpotType(from text: String) -> SpotType {
        let lower = text.lowercased()
        if lower.contains("吃") || lower.contains("美食") || lower.contains("餐厅") || lower.contains("咖啡") || lower.contains("bar") || lower.contains("restaurant") || lower.contains("cafe") || lower.contains("🍜") || lower.contains("🍣") || lower.contains("🍕") || lower.contains("🍔") { return .food }
        if lower.contains("买") || lower.contains("购物") || lower.contains("商场") || lower.contains("shop") || lower.contains("mall") || lower.contains("🛍️") { return .shopping }
        if lower.contains("住") || lower.contains("酒店") || lower.contains("民宿") || lower.contains("hotel") || lower.contains("🏨") { return .hotel }
        if lower.contains("演出") || lower.contains("演唱会") || lower.contains("concert") || lower.contains("🎵") || lower.contains("🎭") { return .performance }
        return .sightseeing
    }

    private func cleanSpotName(_ name: String) -> String {
        name.replacingOccurrences(of: "^[\\s:*\\-–—#\\d.、)]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s:*]+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Models

struct ClipboardImportResult {
    let rawText: String
    let suggestedSpots: [ImportedSpot]
    let suggestedDates: (start: Date?, end: Date?)
    let suggestedBudget: Double?
}

struct ImportedSpot: Identifiable {
    let id = UUID()
    let name: String
    let type: SpotType
    var notes: String?
    let source: ImportSource

    enum ImportSource {
        case emoji
        case numbered
        case marker
        case dash
    }
}
