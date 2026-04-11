import Foundation
import EventKit
import Combine

@MainActor
class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    @Published var isAuthorized: Bool = false

    private init() {}

    // MARK: - Permission

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted
            return granted
        } catch {
            print("Calendar access denied: \(error)")
            isAuthorized = false
            return false
        }
    }

    // MARK: - Create Event

    func createEvent(for travel: Travel) async -> String? {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return nil }
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = travel.name
        event.startDate = travel.startDate
        event.endDate = travel.endDate
        event.calendar = eventStore.defaultCalendarForNewEvents

        let destinationSummary = travel.itineraries.compactMap { $0.destination }.first
        if let dest = destinationSummary {
            event.notes = String(format: "calendar.travel.notes".localized, travel.name, dest, travel.durationDays)
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Failed to create calendar event: \(error)")
            return nil
        }
    }

    // MARK: - Update Event

    func updateEvent(for travel: Travel) async {
        guard let eventId = travel.calendarEventId else { return }
        guard let event = eventStore.event(withIdentifier: eventId) else { return }

        event.title = travel.name
        event.startDate = travel.startDate
        event.endDate = travel.endDate

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Failed to update calendar event: \(error)")
        }
    }

    // MARK: - Remove Event

    func removeEvent(for travel: Travel) async {
        guard let eventId = travel.calendarEventId else { return }
        guard let event = eventStore.event(withIdentifier: eventId) else { return }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            print("Failed to remove calendar event: \(error)")
        }
    }
}
