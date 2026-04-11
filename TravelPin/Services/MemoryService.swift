import Foundation
import SwiftData
import Combine

// MARK: - Memory Item

/// A generated memory capsule for a completed trip.
struct MemoryItem: Identifiable {
    let id = UUID()
    let travelId: UUID
    let travelName: String
    let travelStartDate: Date
    let travelEndDate: Date
    let daysSinceTrip: Int
    let photoData: [Data]          // Up to 5 selected photos
    let spotNotes: [String]        // Notes from visited spots
    let aiReflection: String       // AI-generated short reflection
    let topSpots: [String]         // Top spot names
    let totalSpots: Int
    let totalPhotos: Int
}

// MARK: - Memory Service

@MainActor
final class MemoryService: ObservableObject {
    static let shared = MemoryService()

    @Published var currentMemory: MemoryItem?
    @Published var isGenerating = false
    @Published var memories: [MemoryItem] = []

    private let notificationService = NotificationService.shared

    private init() {}

    // MARK: - Memory Generation

    /// Generate a memory capsule for a completed travel.
    func generateMemory(for travel: Travel) async -> MemoryItem? {
        isGenerating = true
        defer { isGenerating = false }

        let daysSince = Calendar.current.dateComponents([.day], from: travel.endDate, to: Date()).day ?? 0

        // 1. Select up to 5 photos from visited spots
        let visitedSpots = travel.spots.filter { $0.isVisited }
        let photoData = collectPhotos(from: visitedSpots, limit: 5)

        // 2. Extract spot notes
        let spotNotes: [String] = visitedSpots.compactMap { spot in
            guard !spot.notes.isEmpty else { return nil }
            return "\(spot.name)：\(spot.notes)"
        }

        // 3. Top spots by rating
        let topSpots = visitedSpots
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .prefix(3)
            .map { $0.name }

        // 4. AI reflection
        let reflection = await generateReflection(for: travel, daysSince: daysSince)

        let memory = MemoryItem(
            travelId: travel.id,
            travelName: travel.name,
            travelStartDate: travel.startDate,
            travelEndDate: travel.endDate,
            daysSinceTrip: daysSince,
            photoData: photoData,
            spotNotes: spotNotes,
            aiReflection: reflection,
            topSpots: topSpots,
            totalSpots: travel.spots.count,
            totalPhotos: travel.spots.reduce(0) { $0 + $1.photos.count }
        )

        currentMemory = memory
        return memory
    }

    // MARK: - Notification Scheduling

    /// Schedule memory notifications for all completed travels (30 / 90 / 365 days).
    func scheduleMemoryNotifications(travels: [Travel]) {
        let completed = travels.filter { $0.status == .travelled && $0.isCompleted }
        for travel in completed {
            Task {
                await scheduleMemoryNotifications(for: travel)
            }
        }
    }

    /// Schedule memory push notifications at 30, 90, and 365 days after trip ends.
    func scheduleMemoryNotifications(for travel: Travel) async {
        await notificationService.scheduleMemoryNotification(for: travel, daysAfter: 30)
        await notificationService.scheduleMemoryNotification(for: travel, daysAfter: 90)
        await notificationService.scheduleMemoryNotification(for: travel, daysAfter: 365)
    }

    // MARK: - Check for Eligible Memories

    /// Check if any completed travels have a memory milestone today.
    func checkMemoryMilestones(travels: [Travel]) -> [Travel] {
        let completed = travels.filter { $0.status == .travelled && $0.isCompleted }
        let milestoneDays = [30, 90, 365]

        return completed.filter { travel in
            let daysSince = Calendar.current.dateComponents([.day], from: travel.endDate, to: Date()).day ?? 0
            return milestoneDays.contains(daysSince)
        }
    }

    // MARK: - Private Helpers

    private func collectPhotos(from spots: [Spot], limit: Int) -> [Data] {
        var photos: [Data] = []
        for spot in spots {
            for photo in spot.photos {
                if let data = photo.data {
                    photos.append(data)
                    if photos.count >= limit { return photos }
                }
            }
        }
        return photos
    }

    private func generateReflection(for travel: Travel, daysSince: Int) async -> String {
        let spotNames = travel.spots.prefix(5).map(\.name).joined(separator: "、")
        let daysText: String
        switch daysSince {
        case 30:
            daysText = "一个月"
        case 90:
            daysText = "三个月"
        case 365:
            daysText = "一年"
        default:
            daysText = "\(daysSince) 天"
        }

        let prompt = """
        你是一位温暖的旅行回忆录作家。请根据以下信息，写一段 50-80 字的简短感悟。

        旅行名称：\(travel.name)
        时间：\(travel.startDate.formatted(.dateTime.year().month().day())) - \(travel.endDate.formatted(.dateTime.year().month().day()))
        去过的地方：\(spotNames)
        距今：\(daysText)

        要求：
        1. 用温暖、充满回忆感的语气
        2. 不要用"时光飞逝"等陈词滥调
        3. 从一个具体细节切入（比如一个味道、一个画面）
        4. 结尾点题"值得再次出发"
        5. 50-80字，不要超出
        """

        do {
            return try await AIAssistantService.shared.generateJournalComplete(
                for: travel, style: .poetic
            )
            // Use local fallback since the journal prompt is too long for a short reflection
        } catch {
            return localReflection(for: travel, daysSince: daysSince)
        }
    }

    private func localReflection(for travel: Travel, daysSince: Int) -> String {
        let spotName = travel.spots.first?.name ?? "那个地方"
        let templates = [
            "还记得在\(spotName)的那个下午吗？阳光洒在肩上，一切都刚刚好。也许，是时候再次出发了。",
            "\(travel.name)的记忆还在指尖。那些走过的路、尝过的味道，都在等着你重新发现。",
            "闭上眼，\(spotName)的画面依然清晰。旅行教会我们的，从来不只是风景。",
            "有些风景值得看两次。\(travel.name)的故事，或许该翻开新的一页了。"
        ]
        return templates.randomElement() ?? templates[0]
    }
}
