import SwiftUI
import SwiftData
import CoreLocation

/// A high-end, vertical "Long Scroll" export view that visualizes the trip as a logical trail.
/// Features a continuous time-axis, connected spot nodes, and key performance metrics.
struct LongTrailExportView: View {
    let travel: Travel
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet = false
    
    private var sortedSpots: [Spot] {
        travel.spots.sorted { ($0.actualDate ?? $0.estimatedDate ?? Date.distantPast) < ($1.actualDate ?? $1.estimatedDate ?? Date.distantPast) }
    }
    
    private var insight: TravelLogicService.TripInsight {
        TravelLogicService.generateInsight(for: travel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    
                    trailSection
                    
                    footerSection
                }
                .background(TPDesign.background)
            }
            .navigationTitle(locKey: "export.long_trail.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(locKey: "common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // In a real app, we would render this to an image
                        showingExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(travel.name)
                        .font(TPDesign.editorialSerif(32))
                    Text(travel.dateRangeString)
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: travel.type.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(TPDesign.leicaRed)
            }
            
            Divider()
            
            HStack(spacing: 24) {
                statBox(label: "LOGIC.STAT.DISTANCE", value: String(format: "%.1f km", insight.distanceTravelled))
                statBox(label: "LOGIC.STAT.COST", value: String(format: "¥%.0f", insight.totalCost))
                statBox(label: "LOGIC.STAT.RATE", value: String(format: "%.0f%%", insight.completionRate * 100))
            }
        }
        .padding(32)
        .background(TPDesign.secondaryBackground)
    }
    
    private var trailSection: some View {
        ZStack(alignment: .leading) {
            // The Logic Axis
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [TPDesign.leicaRed, TPDesign.warmAmber, TPDesign.leicaRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .padding(.leading, 40)
            
            VStack(alignment: .leading, spacing: 40) {
                ForEach(sortedSpots) { spot in
                    spotNode(spot)
                }
            }
            .padding(.vertical, 40)
        }
    }
    
    private func spotNode(_ spot: Spot) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Node indicator
            ZStack {
                Circle()
                    .fill(TPDesign.background)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(spot.isVisited ? TPDesign.leicaRed : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
            .padding(.leading, 29)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(spot.name)
                        .font(TPDesign.bodyFont(18, weight: .bold))
                    Spacer()
                    if let cost = spot.cost, cost > 0 {
                        Text("¥\(Int(cost))")
                            .font(TPDesign.captionFont())
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(TPDesign.alabaster)
                            .clipShape(Capsule())
                    }
                }
                
                if let date = spot.actualDate ?? spot.estimatedDate {
                    Text(date.formatted(.dateTime.hour().minute()))
                        .font(TPDesign.captionFont())
                        .foregroundStyle(.secondary)
                }
                
                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .padding(.leading, 12)
                        .overlay(
                            Rectangle()
                                .fill(TPDesign.leicaRed.opacity(0.2))
                                .frame(width: 2)
                                .padding(.vertical, 2),
                            alignment: .leading
                        )
                }
                
                // Photo preview if available
                if let firstPhoto = spot.photos.first {
                    Image(systemName: "photo") // Placeholder
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                }
            }
            .padding(.trailing, 32)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 20) {
            Divider()
            
            Text(locKey: "settings.about.quote")
                .font(TPDesign.editorialSerif(16))
                .italic()
                .foregroundStyle(.secondary)
            
            HStack {
                Image("AppIcon") // Placeholder
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading) {
                    Text("TravelPin")
                        .font(TPDesign.bodyFont(14, weight: .black))
                    Text("Design by Logic")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(40)
        .background(TPDesign.secondaryBackground)
    }
    
    private func statBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(locKey: label)
                .font(TPDesign.overline())
                .foregroundStyle(.secondary)
            Text(value)
                .font(TPDesign.bodyFont(20, weight: .black))
        }
    }
}

#Preview {
    LongTrailExportView(travel: Travel(name: "京都物语"))
}
