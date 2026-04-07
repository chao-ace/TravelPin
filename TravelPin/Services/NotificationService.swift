import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Trip Reminders

    /// Schedule a reminder 1 day before the trip starts
    func scheduleTripReminder(for travel: Travel) async {
        let authorized = await requestPermission()
        guard authorized else { return }

        // Cancel existing reminders for this travel
        cancelReminder(for: travel.id)

        // Schedule 1-day-before reminder
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: travel.startDate)
        guard let reminderDate, reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "旅途将至"
        content.body = "\(travel.name) 明天就要出发了！别忘了检查行李清单 ✈️"
        content.sound = .default
        content.badge = NSNumber(value: 1)

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trip_\(travel.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)

        // Schedule departure day reminder
        let departContent = UNMutableNotificationContent()
        departContent.title = "今天出发！"
        departContent.body = "\(travel.name) 的旅程从今天开始，祝你旅途愉快 🌟"
        departContent.sound = .default

        let departComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: travel.startDate)
        let departTrigger = UNCalendarNotificationTrigger(dateMatching: departComponents, repeats: false)

        let departRequest = UNNotificationRequest(
            identifier: "trip_depart_\(travel.id.uuidString)",
            content: departContent,
            trigger: departTrigger
        )

        try? await center.add(departRequest)
    }

    /// Schedule a packing reminder 3 days before
    func schedulePackingReminder(for travel: Travel) async {
        let authorized = await requestPermission()
        guard authorized else { return }

        cancelPackingReminder(for: travel.id)

        let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: travel.startDate)
        guard let reminderDate, reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "收拾行李提醒"
        content.body = "\(travel.name) 还有3天出发，该准备行李了 🧳"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "pack_\(travel.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Schedule a trip-end review reminder
    func scheduleReviewReminder(for travel: Travel) async {
        let authorized = await requestPermission()
        guard authorized else { return }

        cancelReviewReminder(for: travel.id)

        let reminderDate = Calendar.current.date(byAdding: .day, value: 1, to: travel.endDate)
        guard let reminderDate, reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "旅程回顾"
        content.body = "\(travel.name) 已经结束了，来记录旅途中的美好回忆吧 📸"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "review_\(travel.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Cancel

    func cancelReminder(for id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "trip_\(id.uuidString)",
            "trip_depart_\(id.uuidString)",
            "pack_\(id.uuidString)",
            "review_\(id.uuidString)"
        ])
    }

    func cancelPackingReminder(for id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["pack_\(id.uuidString)"])
    }

    func cancelReviewReminder(for id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["review_\(id.uuidString)"])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }
}
