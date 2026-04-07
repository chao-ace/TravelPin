import Foundation
import CoreLocation
import SwiftData

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
            status: TravelStatus.travelled.rawValue,
            type: TravelType.tourism.rawValue
        )
        
        let day1 = Itinerary(day: 1, origin: "CDG Airport", destination: "Le Marais")
        let spot1 = Spot(name: "Eiffel Tower", type: SpotType.sightseeing.rawValue, notes: "Best at sunset.")
        spot1.latitude = 48.8584
        spot1.longitude = 2.2945
        
        let spot2 = Spot(name: "Louvre Museum", type: SpotType.sightseeing.rawValue, notes: "Huge collection.")
        spot2.latitude = 48.8606
        spot2.longitude = 2.3376
        
        spot1.itinerary = day1
        spot2.itinerary = day1
        travel.itineraries = [day1]
        travel.spots = [spot1, spot2]
        
        return travel
    }
    
    private static func generateTokyoTrip() -> Travel {
        let travel = Travel(
            name: "Tokyo Cyberpunk Night",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            status: TravelStatus.travelled.rawValue,
            type: TravelType.chill.rawValue
        )
        
        let day1 = Itinerary(day: 1, origin: "Shinjuku", destination: "Shibuya")
        let spot1 = Spot(name: "Shinjuku Gyoen", type: SpotType.sightseeing.rawValue, notes: "Peaceful garden.")
        spot1.latitude = 35.6852
        spot1.longitude = 139.7101
        
        let spot2 = Spot(name: "Robot Restaurant", type: SpotType.fun.rawValue, notes: "Wild experience.")
        spot2.latitude = 35.6943
        spot2.longitude = 139.7028
        
        spot1.itinerary = day1
        spot2.itinerary = day1
        travel.itineraries = [day1]
        travel.spots = [spot1, spot2]
        
        return travel
    }
    
    private static func generateKyotoTrip() -> Travel {
        let travel = Travel(
            name: "Kyoto Zen Gardens",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 4),
            status: TravelStatus.travelled.rawValue,
            type: TravelType.tourism.rawValue
        )
        
        let day1 = Itinerary(day: 1, origin: "Kyoto Station", destination: "Arashiyama")
        let spot1 = Spot(name: "Kinkaku-ji", type: SpotType.sightseeing.rawValue, notes: "The Golden Pavilion.")
        spot1.latitude = 35.0394
        spot1.longitude = 135.7292
        
        spot1.itinerary = day1
        travel.itineraries = [day1]
        travel.spots = [spot1]
        
        return travel
    }
    
    /// Deep clones a travel object including its itineraries and spots
    static func deepClone(travel: Travel) -> Travel {
        let copy = Travel(name: travel.name, startDate: travel.startDate, endDate: travel.endDate, status: travel.status.rawValue, type: travel.type.rawValue)
        
        // Use PersistentIdentifier to track mappings between original and cloned itineraries
        var itineraryMapping = [PersistentIdentifier: Itinerary]()
        
        for itinerary in travel.itineraries {
            let clonedItinerary = Itinerary(day: itinerary.day, origin: itinerary.origin, destination: itinerary.destination, isCompleted: itinerary.isCompleted)
            clonedItinerary.travel = copy
            copy.itineraries.append(clonedItinerary)
            itineraryMapping[itinerary.persistentModelID] = clonedItinerary
        }
        
        for spot in travel.spots {
            let clonedSpot = Spot(name: spot.name, type: spot.type.rawValue, status: spot.status.rawValue, estimatedDate: spot.estimatedDate, actualDate: spot.actualDate, sequence: spot.sequence, notes: spot.notes)
            clonedSpot.travel = copy
            
            // Link to cloned itinerary if it was linked in original
            if let originalItinerary = spot.itinerary,
               let clonedItinerary = itineraryMapping[originalItinerary.persistentModelID] {
                clonedSpot.itinerary = clonedItinerary
            }
            
            copy.spots.append(clonedSpot)
        }
        
        for item in travel.luggageItems {
            let clonedItem = LuggageItem(name: item.name, categoryRaw: item.category.rawValue, isChecked: item.isChecked)
            clonedItem.travel = copy
            copy.luggageItems.append(clonedItem)
        }
        
        return copy
    }
}
