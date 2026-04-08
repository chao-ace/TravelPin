import Foundation
import ActivityKit
import SwiftUI

struct ItineraryActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentSpotName: String
        var progress: Double // 0.0 to 1.0
        var totalSpots: Int
        var completedSpots: Int
    }

    var travelName: String
    var dayNumber: Int
}

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    @discardableResult
    func startItineraryActivity(travel: Travel, itinerary: Itinerary) -> Activity<ItineraryActivityAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        
        // End any existing activities first
        endAllActivities()
        
        let attributes = ItineraryActivityAttributes(
            travelName: travel.name,
            dayNumber: itinerary.day
        )
        
        let completed = travel.luggageItems.filter { $0.isChecked }.count // Using a similar logic or spots
        // Actually, let's use spots completed in that itinerary day
        let daySpots = travel.spots.filter { $0.itinerary?.id == itinerary.id }
        let total = daySpots.count
        let progress = total > 0 ? 0.0 : 1.0 // Initial
        
        let state = ItineraryActivityAttributes.ContentState(
            currentSpotName: itinerary.destination,
            progress: progress,
            totalSpots: total,
            completedSpots: 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            print("Started Live Activity: \(activity.id)")
            return activity
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateActivity(completedSpots: Int, totalSpots: Int, currentSpotName: String) {
        Task {
            let progress = totalSpots > 0 ? Double(completedSpots) / Double(totalSpots) : 1.0
            let updatedState = ItineraryActivityAttributes.ContentState(
                currentSpotName: currentSpotName,
                progress: progress,
                totalSpots: totalSpots,
                completedSpots: completedSpots
            )
            
            for activity in Activity<ItineraryActivityAttributes>.activities {
                await activity.update(.init(state: updatedState, staleDate: nil))
            }
        }
    }
    
    func endAllActivities() {
        Task {
            for activity in Activity<ItineraryActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
