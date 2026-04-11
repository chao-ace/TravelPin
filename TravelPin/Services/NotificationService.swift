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
        content.title = "notif.trip_upcoming.title".localized
        content.body = String(format: "notif.trip_upcoming.body".localized, travel.name)
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
        departContent.title = "notif.trip_depart.title".localized
        departContent.body = String(format: "notif.trip_depart.body".localized, travel.name)
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
        content.title = "notif.packing.title".localized
        content.body = String(format: "notif.packing.body".localized, travel.name)
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
        content.title = "notif.review.title".localized
        content.body = String(format: "notif.review.body".localized, travel.name)
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

    // MARK: - Spot Arrival Notification

    /// Schedule a notification when the user arrives near a spot.
    func scheduleSpotArrivalNotification(for spot: Spot, in travel: Travel) async {
        let authorized = await requestPermission()
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = String(format: "notif.spot_arrival.title".localized, spot.name)
        content.body = "notif.spot_arrival.body".localized
        content.sound = .default
        content.userInfo = ["spotId": spot.id.uuidString, "travelId": travel.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "spot_arrival_\(spot.id.uuidString)",
            content: content,
            trigger: nil // Delivered immediately by LocationService region monitoring
        )

        try? await center.add(request)
    }

    // MARK: - Memory Notification

    /// Schedule a memory notification 30 days after trip ends.
    func scheduleMemoryNotification(for travel: Travel) async {
        await scheduleMemoryNotification(for: travel, daysAfter: 30)
    }

    /// Schedule a memory notification at a specific number of days after trip ends.
    func scheduleMemoryNotification(for travel: Travel, daysAfter: Int) async {
        let authorized = await requestPermission()
        guard authorized else { return }

        let identifier = "memory_\(daysAfter)_\(travel.id.uuidString)"

        // Cancel existing for this milestone
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let reminderDate = Calendar.current.date(byAdding: .day, value: daysAfter, to: travel.endDate)
        guard let reminderDate, reminderDate > Date() else { return }

        let daysLabel: String
        switch daysAfter {
        case 30: daysLabel = "一个月"
        case 90: daysLabel = "三个月"
        case 365: daysLabel = "一年"
        default: daysLabel = "\(daysAfter) 天"
        }

        let content = UNMutableNotificationContent()
        content.title = String(format: "notif.memory.title".localized, travel.name)
        content.body = String(format: "notif.memory.milestone.body".localized, travel.name, daysLabel)
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.userInfo = [
            "travelId": travel.id.uuidString,
            "memoryDaysAgo": daysAfter,
            "type": "memory_capsule"
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
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

    func cancelMemoryNotification(for id: UUID) {
        let identifiers = [30, 90, 365].map { "memory_\($0)_\(id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
