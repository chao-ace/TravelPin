import Foundation
import SwiftData

@Model
final class LuggageItem {
    // MARK: - Identity & Metadata
    @Attribute(.unique) var id: UUID = UUID()
    var lastSyncedAt: Date?
    var isDeleted: Bool = false

    // MARK: - Core Properties
    var name: String = ""
    var categoryRaw: String = "Clothes"
    var isChecked: Bool = false
    var quantity: Int = 1
    var notes: String = ""
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    // MARK: - AI Suggestions
    var isAISuggested: Bool = false
    var confidenceScore: Double?

    // MARK: - Relationships
    var travel: Travel?

    init(
        name: String,
        categoryRaw: String = "Clothes",
        isChecked: Bool = false,
        quantity: Int = 1,
        notes: String = "",
        sortOrder: Int = 0,
        isAISuggested: Bool = false,
        confidenceScore: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = categoryRaw
        self.isChecked = isChecked
        self.quantity = max(1, quantity)
        self.notes = notes
        self.sortOrder = sortOrder
        self.isAISuggested = isAISuggested
        self.confidenceScore = confidenceScore
        self.createdAt = Date()
    }
}

// MARK: - Computed Accessors

extension LuggageItem {
    var category: LuggageCategory {
        get { LuggageCategory(rawValue: categoryRaw) ?? .clothes }
        set { categoryRaw = newValue.rawValue }
    }
}

// MARK: - LuggageCategory

enum LuggageCategory: String, CaseIterable, Codable {
    case clothes = "Clothes"
    case products = "Products"
    case electronics = "Electronics"
    case essentials = "Essentials"
    case other = "Other"

    var displayName: String { self.rawValue }

    var icon: String {
        switch self {
        case .clothes: return "shirt"
        case .products: return "drop.fill"
        case .electronics: return "bolt.fill"
        case .essentials: return "star.fill"
        case .other: return "bag"
        }
    }

    var systemColor: String {
        switch self {
        case .clothes: return "blue"
        case .products: return "teal"
        case .electronics: return "orange"
        case .essentials: return "red"
        case .other: return "gray"
        }
    }
}
