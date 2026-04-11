import Foundation
import SwiftUI
import Combine

// MARK: - Travel DNA Model

/// A user's personalized travel profile derived from historical travel data.
struct TravelDNA {
    let travelerType: String           // e.g. "美食探索者"
    let travelerTypeEN: String         // e.g. "Food Explorer"
    let travelerTypeIcon: String       // SF Symbol

    let spotTypeDistribution: [SpotTypeRatio]
    let travelTypeDistribution: [TravelTypeRatio]
    let averageBudgetPerDay: Double?
    let totalTrips: Int
    let totalSpots: Int
    let totalDays: Int
    let totalPhotos: Int
    let favoriteCities: [String]
    let travelFrequency: String        // e.g. "每月 1 次"
    let longestTrip: String
    let yearStarted: Int?

    // Personality traits
    let personalityTags: [String]      // e.g. ["早鸟型", "深度游", "摄影控"]
    let travelMotto: String            // AI or template-generated motto
}

struct SpotTypeRatio: Identifiable {
    let id = UUID()
    let type: SpotType
    let percentage: Int
    let count: Int
}

struct TravelTypeRatio: Identifiable {
    let id = UUID()
    let type: TravelType
    let percentage: Int
    let count: Int
}

// MARK: - Travel DNA Service

@MainActor
final class TravelDNAService: ObservableObject {
    static let shared = TravelDNAService()

    @Published var dna: TravelDNA?
    @Published var isAnalyzing = false

    private init() {}

    // MARK: - DNA Generation

    /// Analyze all completed travels and generate a Travel DNA profile.
    func generateDNA(from travels: [Travel]) -> TravelDNA {
        let completed = travels.filter { $0.status == .travelled || $0.isCompleted }
        guard !completed.isEmpty else {
            return emptyDNA
        }

        // 1. Spot type distribution
        let allSpots = completed.flatMap { $0.spots }
        let spotTypeCounts = Dictionary(grouping: allSpots, by: { $0.type })
            .mapValues { $0.count }
        let totalSpotsCount = allSpots.count
        let spotDistribution = spotTypeCounts.map { type, count in
            SpotTypeRatio(
                type: type,
                percentage: totalSpotsCount > 0 ? Int(Double(count) / Double(totalSpotsCount) * 100) : 0,
                count: count
            )
        }.sorted { $0.percentage > $1.percentage }

        // 2. Travel type distribution
        let travelTypeCounts = Dictionary(grouping: completed, by: { $0.type })
            .mapValues { $0.count }
        let travelDistribution = travelTypeCounts.map { type, count in
            TravelTypeRatio(
                type: type,
                percentage: Int(Double(count) / Double(completed.count) * 100),
                count: count
            )
        }.sorted { $0.percentage > $1.percentage }

        // 3. Average budget per day
        let budgetedTrips = completed.compactMap { travel -> Double? in
            guard let budget = travel.budget, budget > 0 else { return nil }
            return budget / Double(travel.durationDays)
        }
        let avgBudgetPerDay = budgetedTrips.isEmpty ? nil : budgetedTrips.reduce(0, +) / Double(budgetedTrips.count)

        // 4. Favorite cities (from spot addresses)
        let cityCounts = Dictionary(grouping: allSpots.compactMap(\.address)) { address in
            // Extract city name (first component before comma/space)
            address.components(separatedBy: CharacterSet(charactersIn: ",，市"))
                .first?
                .trimmingCharacters(in: .whitespaces) ?? address
        }.mapValues { $0.count }
        let topCities = cityCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        // 5. Determine traveler type
        let (typeLabel, typeEN, typeIcon) = determineTravelerType(spotDistribution: spotDistribution, travelDistribution: travelDistribution)

        // 6. Travel frequency
        let totalDays = completed.reduce(0) { $0 + $1.durationDays }
        let calendar = Calendar.current
        if let firstTrip = completed.last?.startDate,
           let years = calendar.dateComponents([.year], from: firstTrip, to: Date()).year,
           years > 0 {
            let perYear = Double(completed.count) / Double(years)
            if perYear >= 12 {
                // monthly
            } else if perYear >= 4 {
                // quarterly
            }
        }

        // 7. Longest trip
        let longestDays = completed.map(\.durationDays).max() ?? 0

        // 8. Personality tags
        let tags = generatePersonalityTags(
            travels: completed,
            spotDistribution: spotDistribution,
            avgBudget: avgBudgetPerDay
        )

        // 9. Year started
        let yearStarted = completed.last.map { Calendar.current.component(.year, from: $0.startDate) }

        // 10. Travel motto
        let motto = generateMotto(tags: tags, type: typeLabel)

        let totalPhotos = completed.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } }
        let months = completed.count > 0 ? Calendar.current.dateComponents([.month], from: completed.last!.startDate, to: Date()).month ?? 1 : 1
        let frequency = months > 0 ? String(format: "%.1f", Double(completed.count) / Double(months) * 12.0) : "0"

        let dna = TravelDNA(
            travelerType: typeLabel,
            travelerTypeEN: typeEN,
            travelerTypeIcon: typeIcon,
            spotTypeDistribution: spotDistribution,
            travelTypeDistribution: travelDistribution,
            averageBudgetPerDay: avgBudgetPerDay,
            totalTrips: completed.count,
            totalSpots: allSpots.count,
            totalDays: totalDays,
            totalPhotos: totalPhotos,
            favoriteCities: topCities,
            travelFrequency: "每年 \(frequency) 次",
            longestTrip: "\(longestDays) 天",
            yearStarted: yearStarted,
            personalityTags: tags,
            travelMotto: motto
        )

        self.dna = dna
        return dna
    }

    // MARK: - Private Helpers

    private func determineTravelerType(
        spotDistribution: [SpotTypeRatio],
        travelDistribution: [TravelTypeRatio]
    ) -> (String, String, String) {
        // Check dominant travel type first
        if let dominantTravel = travelDistribution.first, dominantTravel.percentage >= 50 {
            switch dominantTravel.type {
            case .concert:
                return ("追星达人", "Concert Chaser", "music.note")
            case .chill:
                return ("休闲度假者", "Leisure Seeker", "sun.max")
            case .business:
                return ("商务旅行家", "Business Voyager", "briefcase")
            default: break
            }
        }

        // Then check dominant spot type
        if let dominantSpot = spotDistribution.first, dominantSpot.percentage >= 30 {
            switch dominantSpot.type {
            case .food:
                return ("美食探索者", "Food Explorer", "fork.knife")
            case .sightseeing:
                return ("文化旅行者", "Culture Traveler", "binoculars")
            case .shopping:
                return ("购物达人", "Shopping Expert", "bag")
            case .fun:
                return ("冒险玩家", "Adventure Seeker", "star")
            default: break
            }
        }

        return ("全能旅行家", "All-Round Traveler", "globe")
    }

    private func generatePersonalityTags(
        travels: [Travel],
        spotDistribution: [SpotTypeRatio],
        avgBudget: Double?
    ) -> [String] {
        var tags: [String] = []

        // Budget style
        if let budget = avgBudget {
            if budget > 1500 { tags.append("品质旅行") }
            else if budget > 500 { tags.append("精打细算") }
            else { tags.append("极简背包客") }
        }

        // Photo style
        let avgPhotosPerTrip = travels.reduce(0) { $0 + $1.spots.reduce(0) { $0 + $1.photos.count } } / max(travels.count, 1)
        if avgPhotosPerTrip > 20 { tags.append("摄影控") }

        // Spot density
        let avgSpotsPerDay = travels.reduce(0) { $0 + $1.spots.count } / max(travels.reduce(0) { $0 + $1.durationDays }, 1)
        if avgSpotsPerDay > 3 { tags.append("打卡狂人") }
        else if avgSpotsPerDay < 2 { tags.append("慢旅行") }

        // Duration style
        let avgDuration = travels.map(\.durationDays).reduce(0, +) / max(travels.count, 1)
        if avgDuration > 7 { tags.append("深度游") }
        else if avgDuration <= 2 { tags.append("周末闪现") }

        // Companion style
        let soloTrips = travels.filter { $0.companionNames.isEmpty }.count
        if soloTrips > travels.count / 2 { tags.append("独行侠") }
        else if travels.allSatisfy({ !$0.companionNames.isEmpty }) { tags.append("社交旅行者") }

        return Array(tags.prefix(4))
    }

    private func generateMotto(tags: [String], type: String) -> String {
        let mottos: [String] = [
            "世界是一本书，不旅行的人只读了一页。",
            "旅行的意义不在于去了哪里，而在于你变成了谁。",
            "每一次出发，都是对日常的一次温柔反叛。",
            "走得越远，离自己越近。",
            "最好的旅行，是让你回到家后有了新的目光。",
            "人生就是一场漫长的探索旅程。"
        ]
        return mottos.randomElement() ?? mottos[0]
    }

    private var emptyDNA: TravelDNA {
        TravelDNA(
            travelerType: "旅行新手",
            travelerTypeEN: "Travel Rookie",
            travelerTypeIcon: "paperplane",
            spotTypeDistribution: [],
            travelTypeDistribution: [],
            averageBudgetPerDay: nil,
            totalTrips: 0,
            totalSpots: 0,
            totalDays: 0,
            totalPhotos: 0,
            favoriteCities: [],
            travelFrequency: "每年 0 次",
            longestTrip: "0 天",
            yearStarted: nil,
            personalityTags: [],
            travelMotto: "开始你的第一次旅行吧！"
        )
    }
}
