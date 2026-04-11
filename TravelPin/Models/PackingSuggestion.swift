import Foundation

/// Temporary structure for AI-generated packing suggestions.
/// Not a SwiftData model — used only as transport between AI service and UI.
struct PackingSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let categoryRaw: String
    let reason: String
}
