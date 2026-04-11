import Foundation

/// A suggested fix for a scheduling conflict detected during travel planning or execution.
struct ScheduleFix: Identifiable {
    let id = UUID()
    let alertTitle: String
    let alertMessage: String
    let fixType: FixType
    let actions: [FixAction]

    enum FixType {
        case timeOverlap
        case distanceTooFar
        case weatherChange
    }
}

/// An individual actionable fix within a ScheduleFix.
struct FixAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let actionType: FixActionType

    enum FixActionType {
        case shiftLater(spotId: UUID, minutes: Int)
        case skipSpot(spotId: UUID)
        case swapWithAlternative(originalSpotId: UUID)
        case suggestIndoor(spotId: UUID)
    }
}
