import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var selectedTab: Int = 0
    
    private init() {}
    
    func navigateToDiscover() {
        selectedTab = 2
    }
}
