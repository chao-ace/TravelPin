import SwiftUI

struct IntelligenceBanner: View {
    @ObservedObject var intelligence = IntelligenceService.shared
    let travel: Travel
    
    var body: some View {
        if let recommendation = intelligence.activeRecommendation {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    // Intelligence Icon (Magic Wand)
                    ZStack {
                        Circle()
                            .fill(Color.tpAccent.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "wand.and.stars.inverse")
                            .foregroundStyle(Color.tpAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(TPDesign.titleFont(18))
                        
                        Text(recommendation.subtitle)
                            .font(TPDesign.bodyFont(15))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            intelligence.dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(20)
                
                Divider()
                
                // Action Choice
                HStack(spacing: 12) {
                    if recommendation.actionType == .swapLocal {
                        Button {
                            // Apply Swap
                            if let targetID = recommendation.internalSpotID {
                                intelligence.applySwap(in: travel, targetSpotID: targetID)
                            }
                        } label: {
                            Text("Swap My Plans")
                                .font(.caption).bold()
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.tpAccent)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            // Find Inspiration
                            intelligence.dismiss()
                        } label: {
                            Text("Discover Something New")
                                .font(.caption).bold()
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.tpAccent)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Button {
                        withAnimation {
                            intelligence.dismiss()
                        }
                    } label: {
                        Text("Not Now")
                            .font(.caption).bold()
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.tpSurface)
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
            }
            .glassCard(cornerRadius: 24)
            .padding(.horizontal)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .shadow(color: Color.tpAccent.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}
