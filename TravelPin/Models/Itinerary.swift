import Foundation
import SwiftData

@Model
final class Itinerary {
    var id: UUID = UUID()
    var day: Int = 1
    var origin: String = ""
    var destination: String = ""
    var isCompleted: Bool = false
    
    var travel: Travel?
    
    @Relationship(deleteRule: .cascade, inverse: \Spot.itinerary)
    var spots: [Spot] = []
    
    init(day: Int, origin: String, destination: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.day = day
        self.origin = origin
        self.destination = destination
        self.isCompleted = isCompleted
    }
}
