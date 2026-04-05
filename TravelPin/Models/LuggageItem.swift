import Foundation
import SwiftData

@Model
final class LuggageItem {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = "Clothes" // "Clothes", "Products", "Electronics", "Essentials", "Other"
    var isChecked: Bool = false
    
    var travel: Travel?
    
    init(name: String, category: String = "Clothes", isChecked: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isChecked = isChecked
    }
}

enum LuggageCategory: String, CaseIterable {
    case clothes = "Clothes"
    case products = "Products"
    case electronics = "Electronics"
    case essentials = "Essentials"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .clothes: return "tshirt"
        case .products: return "sparkles"
        case .electronics: return "iphone"
        case .essentials: return "briefcase"
        case .other: return "bag"
        }
    }
}
