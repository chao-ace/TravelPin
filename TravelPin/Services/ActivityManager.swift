import Foundation
import ActivityKit
import Combine

class TripActivityManager: ObservableObject {
    static let shared = TripActivityManager()
    
    @Published var currentActivity: Activity<TripActivityAttributes>?
    
    private init() {}
    
    func startTracking(travel: Travel, currentSpot: Spot, nextSpot: Spot?, distance: Double?) {
        // Ensure Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // End existing activity if any
        endTracking()
        
        let attributes = TripActivityAttributes(
            tripName: travel.name,
            startDate: travel.startDate
        )
        
        let initialContentState = TripActivityAttributes.ContentState(
            currentSpotName: currentSpot.name,
            nextSpotName: nextSpot?.name,
            distanceToNext: distance,
            arrivalEstimate: nil, // Could be calculated
            weatherIcon: currentSpot.type.icon,
            temperature: nil // Fetch from IntelligenceService if available
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil // Optional: setup for remote updates
            )
            DispatchQueue.main.async {
                self.currentActivity = activity
            }
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateTracking(currentSpot: Spot, nextSpot: Spot?, distance: Double?, temperature: Double?) {
        Task {
            let updatedState = TripActivityAttributes.ContentState(
                currentSpotName: currentSpot.name,
                nextSpotName: nextSpot?.name,
                distanceToNext: distance,
                arrivalEstimate: nil,
                weatherIcon: currentSpot.type.icon,
                temperature: temperature
            )
            
            for activity in Activity<TripActivityAttributes>.activities {
                await activity.update(.init(state: updatedState, staleDate: nil))
            }
        }
    }
    
    func endTracking() {
        Task {
            for activity in Activity<TripActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            DispatchQueue.main.async {
                self.currentActivity = nil
            }
        }
    }
}
