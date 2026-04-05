import SwiftUI
import MapKit
import SwiftData

struct TravelMapView: View {
    @Bindable var travel: Travel
    @State private var isOfflineMode = false
    @State private var selectedDay: Int = 1
    @State private var isDownloading = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            InteractiveOfflineMap(travel: travel, isOfflineMode: $isOfflineMode)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Button(action: { isOfflineMode.toggle() }) {
                    Image(systemName: isOfflineMode ? "airplane.circle.fill" : "network")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Button(action: downloadAction) {
                    if isDownloading {
                        ProgressView()
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .disabled(isDownloading)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            daySelector
        }
        .navigationTitle("Footprint Map")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func downloadAction() {
        isDownloading = true
        // Placeholder for region download logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDownloading = false
            // Mark as downloaded...
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(travel.itineraries.sorted(by: { $0.day < $1.day })) { itinerary in
                    Button {
                        selectedDay = itinerary.day
                    } label: {
                        Text("Day \(itinerary.day)")
                            .font(.caption).bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedDay == itinerary.day ? Color.tpAccent : Color.tpSurface)
                            .foregroundStyle(selectedDay == itinerary.day ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
        .glassCard(cornerRadius: 0)
    }
}
