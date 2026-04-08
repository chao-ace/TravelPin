import Foundation
import SwiftData

@Model
final class PackingTemplate {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var items: [TemplateItem] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.items = []
    }
}

@Model
final class TemplateItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = "Clothes"
    var quantity: Int = 1
    var notes: String = ""
    
    var template: PackingTemplate?
    
    init(name: String, categoryRaw: String = "Clothes", quantity: Int = 1, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryRaw = categoryRaw
        self.quantity = quantity
        self.notes = notes
    }
}
