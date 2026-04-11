import Foundation

/// Budget allocation categories for travel planning.
/// Used as keys in Travel.budgetBreakdown dictionary.
enum BudgetCategory: String, CaseIterable, Codable {
    case transport      = "Transport"
    case accommodation  = "Accommodation"
    case food           = "Food"
    case tickets        = "Tickets"
    case shopping       = "Shopping"
    case other          = "Other"

    var icon: String {
        switch self {
        case .transport:     return "car"
        case .accommodation: return "bed.double"
        case .food:          return "fork.knife"
        case .tickets:       return "ticket"
        case .shopping:      return "bag"
        case .other:         return "ellipsis.circle"
        }
    }

    var displayName: String {
        "budget.category.\(self.rawValue.lowercased())".localized
    }

    /// Default allocation ratios by travel type.
    static func defaultRatios(for type: TravelType) -> [BudgetCategory: Double] {
        switch type {
        case .tourism:
            return [.transport: 0.30, .accommodation: 0.25, .food: 0.25, .tickets: 0.10, .shopping: 0.10]
        case .concert:
            return [.tickets: 0.40, .transport: 0.25, .food: 0.20, .accommodation: 0.15]
        case .chill:
            return [.accommodation: 0.35, .food: 0.30, .transport: 0.20, .shopping: 0.15]
        case .business:
            return [.transport: 0.40, .accommodation: 0.30, .food: 0.20, .other: 0.10]
        case .other:
            return [.transport: 0.25, .food: 0.25, .accommodation: 0.20, .tickets: 0.15, .other: 0.15]
        }
    }
}
