import SwiftUI

struct MainTabView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("nav.journeys".localized, systemImage: "map")
                }
                .tag(0)
            
            FootprintReviewView()
                .tabItem {
                    Label("nav.footprints".localized, systemImage: "figure.walk")
                }
                .tag(1)
            
            InspirationPlazaView()
                .tabItem {
                    Label("nav.discover".localized, systemImage: "sparkles")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("nav.settings".localized, systemImage: "gearshape")
                }
                .tag(3)
        }
        // Tint color to match Cinematic aesthetic
        .tint(.primary)
    }
}

#Preview {
    MainTabView()
}
