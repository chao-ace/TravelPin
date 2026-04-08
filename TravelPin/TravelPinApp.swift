import SwiftUI
import SwiftData

@main
struct TravelPinApp: App {
    static let container: ModelContainer = {
        let schema = Schema([
            Travel.self,
            Itinerary.self,
            Spot.self,
            LuggageItem.self,
            TravelPhoto.self,
            PublishedTrip.self,
            SocialInteraction.self,
            CollaborationInvite.self,
            CollaboratorProfile.self,
            PackingTemplate.self,
            TemplateItem.self
        ])

        do {
            // Using a simple configuration with CloudKit explicitly disabled to rule out entitlement issues.
            let config = ModelConfiguration("TravelPin", isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("🚨 SwiftData: First load failed (\(error)). Purging store...")

            purgeStoreFiles()

            do {
                let config = ModelConfiguration("TravelPin", isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("🚨 SwiftData: Second load also failed (\(error)). Falling back to in-memory.")
                do {
                    // Note: In-memory stores do not support @Attribute(.externalStorage)
                    // If this fails, the schema itself is invalid for in-memory use.
                    return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                } catch {
                    fatalError("SwiftData: Cannot create ModelContainer even in-memory. Schema may be invalid: \(error)")
                }
            }
        }
    }()

    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                BrandLaunchViewWrapper()
            }
            .environmentObject(LanguageManager.shared)
            .withToast()
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(Self.container)
    }

    // MARK: - Store Recovery

    /// Deletes SwiftData persistent store files so the next launch starts clean.
    private static func purgeStoreFiles() {
        let fm = FileManager.default
        let appGroupIdentifier = "group.com.travelpin.app"
        
        var directories = [fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first].compactMap { $0 }
        if let groupDir = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            directories.append(groupDir)
        }

        // Clean up both explicit "TravelPin" name and default SwiftData naming
        let storeNames = ["TravelPin", "default"]
        let extensions = ["store", "store-wal", "store-shm", "sqlite", "sqlite-wal", "sqlite-shm"]
        
        for dir in directories {
            for name in storeNames {
                for ext in extensions {
                    let url = dir.appendingPathComponent("\(name).\(ext)")
                    try? fm.removeItem(at: url)
                }
            }
        }
    }
}

/// Helper to handle launch visibility without polluting the App entry point
struct BrandLaunchViewWrapper: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunch = true

    var body: some View {
        if showLaunch {
            BrandLaunchView()
                .transition(.opacity)
                .zIndex(2)
                .onAppear {
                    if hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showLaunch = false
                            }
                        }
                    }
                }
                .onChange(of: hasCompletedOnboarding) { _, completed in
                    if completed {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            showLaunch = false
                        }
                    }
                }
        }
    }
}
