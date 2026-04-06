import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]

    @State private var showingAddTravel = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [.tpSurface.opacity(0.8), .tpSurface], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection

                        if travels.isEmpty {
                            emptyStateSection
                        } else {
                            // Featured trip poster preview
                            if let latestTravel = travels.first {
                                featuredTripSection(latestTravel)
                            }

                            travelListSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("dashboard.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTravel.toggle() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.tpAccent)
                            .padding(8)
                            .background(Color.tpAccent.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddTravel) {
                AddTravelView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(locKey: "dashboard.header.title")
                .font(TPDesign.titleFont(28))
            Text(locKey: "dashboard.header.subtitle")
                .font(TPDesign.bodyFont())
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Empty State (Cinematic)

    private var emptyStateSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)

            // Cinematic empty state with film grain
            ZStack {
                // Pulsing aurora gradient background
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.tpAccent.opacity(0.15),
                                Color.purple.opacity(0.1),
                                Color.tpAccent.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                    .filmGrain(intensity: 0.03)

                // Globe icon with subtle animation
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.tpAccent.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text(locKey: "dashboard.empty.title")
                    .font(TPDesign.cinematicTitle(24))
                    .multilineTextAlignment(.center)

                Text(locKey: "dashboard.empty.subtitle")
                    .font(TPDesign.bodyFont())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: { showingAddTravel = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(locKey: "dashboard.empty.button")
                        .fontWeight(.semibold)
                }
                .font(.body)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.tpAccent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Featured Trip

    private func featuredTripSection(_ travel: Travel) -> some View {
        NavigationLink(destination: TripPosterView(travel: travel)) {
            ZStack(alignment: .bottomLeading) {
                // Background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.tpAccent.opacity(0.8), Color.tpAccent.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)

                // Cover photo if available
                if let firstSpot = travel.spots.first,
                   let data = firstSpot.photoData.first,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.black.opacity(0.3))
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(locKey: "dashboard.featured.badge")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(travel.name)
                        .font(TPDesign.cinematicTitle(28))
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        Label(travel.status.displayName, systemImage: "circle.fill")
                        Label("\(travel.itineraries.count) \("common.days".localized)", systemImage: "calendar")
                        Label("\(travel.spots.count) \("common.spots".localized)", systemImage: "mappin")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Travel List

    private var travelListSection: some View {
        VStack(spacing: 20) {
            ForEach(travels) { travel in
                NavigationLink(value: travel) {
                    TravelCard(travel: travel)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Travel.self) { travel in
            TravelDetailView(travel: travel)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Travel.self, inMemory: true)
}
