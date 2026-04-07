import SwiftUI

struct MainTabView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var appState = AppState.shared

    @Namespace private var tabIndicator

    private let tabs: [(icon: String, locKey: String, tag: Int)] = [
        ("map", "nav.journeys", 0),
        ("shoeprints.fill", "nav.footprints", 1),
        ("sparkles", "nav.discover", 2),
        ("gearshape", "nav.settings", 3)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch appState.selectedTab {
                case 0: DashboardView()
                case 1: NavigationStack { FootprintReviewView() }
                case 2: InspirationPlazaView()
                case 3: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Tab Bar
            if !appState.isTabBarHidden {
                floatingTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.isTabBarHidden)
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                let isSelected = appState.selectedTab == tab.tag
                Button {
                    TPHaptic.selection()
                    withAnimation(TPDesign.springDefault) {
                        appState.selectedTab = tab.tag
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? .white : TPDesign.textTertiary)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .shadow(
                                color: isSelected ? TPDesign.celestialBlue.opacity(0.4) : .clear,
                                radius: 8
                            )

                        Text(locKey: tab.locKey)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : TPDesign.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(TPDesign.accentGradient)
                                .matchedGeometryEffect(id: "tab_indicator", in: tabIndicator)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // High-luminance Crystal Glass Base
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .blur(radius: 0.5)
                
                // Subtle Dopamine Tint
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [TPDesign.celestialBlue.opacity(0.05), TPDesign.celestialBlue.opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadowFloating()
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

#Preview {
    MainTabView()
}
