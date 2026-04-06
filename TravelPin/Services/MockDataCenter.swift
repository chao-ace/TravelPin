import Foundation
import CoreLocation

struct MockDataCenter {
    static func getPublicTrips() -> [Travel] {
        let trips = [
            generateParisTrip(),
            generateTokyoTrip(),
            generateKyotoTrip()
        ]
        return trips
    }
    
    private static func generateParisTrip() -> Travel {
        let travel = Travel(
            name: "Paris Architecture Tour",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 5),
            status: .travelled,
            type: .tourism
        )
        
        let day1 = Itinerary(day: 1, origin: "CDG Airport", destination: "Le Marais")
        let spot1 = Spot(name: "Eiffel Tower", type: .sightseeing, notes: "Best at sunset.")
        spot1.latitude = 48.8584
        spot1.longitude = 2.2945
        
        let spot2 = Spot(name: "Louvre Museum", type: .sightseeing, notes: "Huge collection.")
        spot2.latitude = 48.8606
        spot2.longitude = 2.3376
        
        day1.spots = [spot1, spot2]
        travel.itineraries = [day1]
        travel.spots = [spot1, spot2]
        
        return travel
    }
    
    private static func generateTokyoTrip() -> Travel {
        let travel = Travel(
            name: "Tokyo Cyberpunk Night",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            status: .travelled,
            type: .chill
        )
        
        let day1 = Itinerary(day: 1, origin: "Shinjuku", destination: "Shibuya")
        let spot1 = Spot(name: "Shinjuku Gyoen", type: .sightseeing, notes: "Peaceful garden.")
        spot1.latitude = 35.6852
        spot1.longitude = 139.7101
        
        let spot2 = Spot(name: "Robot Restaurant", type: .fun, notes: "Wild experience.")
        spot2.latitude = 35.6943
        spot2.longitude = 139.7028
        
        day1.spots = [spot1, spot2]
        travel.itineraries = [day1]
        travel.spots = [spot1, spot2]
        
        return travel
    }
    
    private static func generateKyotoTrip() -> Travel {
        let travel = Travel(
            name: "Kyoto Zen Gardens",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 4),
            status: .travelled,
            type: .tourism
        )
        
        let day1 = Itinerary(day: 1, origin: "Kyoto Station", destination: "Arashiyama")
        let spot1 = Spot(name: "Kinkaku-ji", type: .sightseeing, notes: "The Golden Pavilion.")
        spot1.latitude = 35.0394
        spot1.longitude = 135.7292
        
        day1.spots = [spot1]
        travel.itineraries = [day1]
        travel.spots = [spot1]
        
        return travel
    }
    
    /// Deep clones a travel object including its itineraries and spots
    static func deepClone(travel: Travel) -> Travel {
        let copy = Travel(
            name: "\(travel.name) (Remix)",
            startDate: Date(),
            endDate: Date().addingTimeInterval(travel.endDate.timeIntervalSince(travel.startDate)),
            status: .wishing,
            type: travel.type
        )
        
        // Map to keep track of cloned itineraries to link spots correctly
        var itineraryMapping: [UUID: Itinerary] = [:]
        
        for itinerary in travel.itineraries {
            let clonedItinerary = Itinerary(
                day: itinerary.day,
                origin: itinerary.origin,
                destination: itinerary.destination,
                isCompleted: false
            )
            clonedItinerary.travel = copy
            itineraryMapping[itinerary.id] = clonedItinerary
            copy.itineraries.append(clonedItinerary)
        }
        
        for spot in travel.spots {
            let clonedSpot = Spot(
                name: spot.name,
                type: spot.type,
                status: .wishing,
                estimatedDate: nil,
                actualDate: nil,
                sequence: spot.sequence,
                notes: spot.notes
            )
            clonedSpot.latitude = spot.latitude
            clonedSpot.longitude = spot.longitude
            clonedSpot.photoData = spot.photoData
            clonedSpot.rating = spot.rating
            clonedSpot.address = spot.address
            clonedSpot.tags = spot.tags
            clonedSpot.cost = spot.cost
            clonedSpot.visitDuration = spot.visitDuration
            
            clonedSpot.travel = copy
            
            // Re-link to cloned itinerary if it was linked in original
            if let originalItinerary = spot.itinerary,
               let clonedItinerary = itineraryMapping[originalItinerary.id] {
                clonedSpot.itinerary = clonedItinerary
                clonedItinerary.spots.append(clonedSpot)
            }
            
            copy.spots.append(clonedSpot)
        }
        
        return copy
    }
}
