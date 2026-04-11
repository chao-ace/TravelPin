import Foundation
import SwiftData

/// Handles deep-copying trips for the Remix feature.
struct TripRemixService {

    /// Creates a deep copy of a trip with all itineraries and spots, reset to Planning status.
    static func remix(_ sourceTravel: Travel, into context: ModelContext) -> Travel {
        let newTravel = Travel(
            name: sourceTravel.name + " (" + "remix.suffix".localized + ")",
            startDate: Date().addingTimeInterval(86400 * 30),
            endDate: Date().addingTimeInterval(86400.0 * Double(30 + sourceTravel.durationDays)),
            status: TravelStatus.planning.rawValue,
            type: sourceTravel.typeRaw
        )
        newTravel.type = sourceTravel.type
        newTravel.companionNames = sourceTravel.companionNames
        newTravel.budget = sourceTravel.budget
        newTravel.currency = sourceTravel.currency

        // Deep copy itineraries
        for sourceItinerary in sourceTravel.itineraries.sorted(by: { $0.day < $1.day }) {
            let newItinerary = Itinerary(
                day: sourceItinerary.day,
                origin: sourceItinerary.origin,
                destination: sourceItinerary.destination
            )
            newItinerary.travel = newTravel

            // Deep copy spots for this itinerary
            let itinerarySpots = sourceTravel.spots.filter {
                $0.itinerary?.persistentModelID == sourceItinerary.persistentModelID
            }.sorted { $0.sequence < $1.sequence }

            for sourceSpot in itinerarySpots {
                let newSpot = Spot(
                    name: sourceSpot.name,
                    type: sourceSpot.typeRaw,
                    status: SpotStatus.planning.rawValue,
                    sequence: sourceSpot.sequence,
                    notes: sourceSpot.notes
                )
                newSpot.latitude = sourceSpot.latitude
                newSpot.longitude = sourceSpot.longitude
                newSpot.address = sourceSpot.address
                newSpot.tags = sourceSpot.tags
                newSpot.estimatedDate = nil  // Reset — user sets their own dates
                newSpot.actualDate = nil
                newSpot.rating = nil
                newSpot.cost = nil
                newSpot.travel = newTravel
                newSpot.itinerary = newItinerary
                newTravel.spots.append(newSpot)
            }

            newTravel.itineraries.append(newItinerary)
        }

        // Also copy spots not assigned to any itinerary
        let unassignedSpots = sourceTravel.spots.filter { $0.itinerary == nil }
        for sourceSpot in unassignedSpots {
            let newSpot = Spot(
                name: sourceSpot.name,
                type: sourceSpot.typeRaw,
                status: SpotStatus.planning.rawValue,
                sequence: sourceSpot.sequence,
                notes: sourceSpot.notes
            )
            newSpot.latitude = sourceSpot.latitude
            newSpot.longitude = sourceSpot.longitude
            newSpot.address = sourceSpot.address
            newSpot.travel = newTravel
            newTravel.spots.append(newSpot)
        }

        context.insert(newTravel)
        try? context.processPendingChanges()
        try? context.save()

        return newTravel
    }
}
