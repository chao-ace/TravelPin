import Foundation
import SwiftData

@Model
final class TravelPhoto {
    @Attribute(.unique) var id: UUID = UUID()
    var data: Data?
    var createdAt: Date = Date()
    
    // Relationships (Single Parent)
    var spot: Spot?
    
    init(data: Data?) {
        self.id = UUID()
        self.data = data
        self.createdAt = Date()
    }
}
