import SwiftUI
import SwiftData

@main
struct TravelPinApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Travel.self,
            Itinerary.self,
            Spot.self,
            LuggageItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var languageManager: LanguageManager = .shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(languageManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
