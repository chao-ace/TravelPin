import SwiftUI
import Combine
import WidgetKit

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: Int = 0
    @Published var isTabBarHidden: Bool = false

    private init() {}

    func navigateToDiscover() {
        selectedTab = 2
    }

    // MARK: - Widget Data Update

    /// Updates shared UserDefaults for widget display
    func updateWidgetData(travels: [Travel]) {
        let defaults = UserDefaults(suiteName: "group.com.travelpin.app") ?? .standard

        // Find next upcoming trip
        let upcomingTrips = travels
            .filter { $0.startDate > Date() && $0.status != .cancelled }
            .sorted { $0.startDate < $1.startDate }

        if let nextTrip = upcomingTrips.first {
            let calendar = Calendar.current
            let daysUntil = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: nextTrip.startDate)).day ?? 0

            defaults.set(nextTrip.name, forKey: "widget_tripName")
            defaults.set(daysUntil, forKey: "widget_daysUntil")
            defaults.set(nextTrip.statusRaw, forKey: "widget_status")
        } else {
            defaults.set("暂无计划", forKey: "widget_tripName")
            defaults.set(0, forKey: "widget_daysUntil")
            defaults.set("Planning", forKey: "widget_status")
        }

        defaults.set(travels.count, forKey: "widget_totalTrips")
        let totalSpots = travels.reduce(0) { $0 + $1.spots.count }
        defaults.set(totalSpots, forKey: "widget_totalSpots")

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }
}
