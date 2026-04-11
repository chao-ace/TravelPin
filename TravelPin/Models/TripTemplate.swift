import Foundation

/// A lightweight, non-persisted struct representing an extractable trip template.
/// Generated on-demand from a completed trip for the "Plan Similar Trip" feature.
struct TripTemplate: Identifiable {
    let id = UUID()
    let sourceTravelId: UUID
    let name: String
    let type: TravelType
    let durationDays: Int
    let dayPlans: [TemplateDayPlan]
    let budget: Double?
    let currency: String
    let successMetrics: TemplateMetrics
}

struct TemplateDayPlan: Identifiable {
    let id = UUID()
    let day: Int
    let spotTemplates: [TemplateSpot]
}

struct TemplateSpot: Identifiable {
    let id = UUID()
    let name: String
    let type: SpotType
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let suggestedDuration: Int? // minutes
}

struct TemplateMetrics {
    let completionRate: Double     // visited / total spots
    let budgetUtilization: Double? // spent / budget
    let avgRating: Double?
    let totalSpots: Int
    let visitedSpots: Int

    var isSuccessful: Bool {
        completionRate >= 0.7 && (budgetUtilization ?? 1.0) <= 1.2
    }
}
