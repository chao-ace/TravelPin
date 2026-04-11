import Foundation

/// Temporary structure for AI-generated itinerary suggestions.
/// Not a SwiftData model — used only as transport between AI service and UI.
struct ItineraryDraft: Identifiable {
    let id = UUID()
    let day: Int
    let origin: String
    let destination: String
    let suggestedSpots: [String]
    let theme: String?
}
