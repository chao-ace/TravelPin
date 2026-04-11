import SwiftUI

/// A logic-driven banner system that adapts to the travel lifecycle:
/// - Pre-travel: Shows logical conflicts and planning alerts.
/// - During-travel: Shows "Now" and "Next" focus points.
/// - Post-travel: Shows a summary of the trip's achievements.
struct LogicClosedLoopBanner: View {
    let travel: Travel
    
    @State private var alerts: [TravelLogicService.LogicAlert] = []
    @State private var activeFocus: (current: Spot?, next: Spot?) = (nil, nil)
    @State private var insight: TravelLogicService.TripInsight? = nil
    
    var body: some View {
        Group {
            switch travel.status {
            case .planning, .wishing:
                planningAlertsView
            case .traveling:
                activeFocusView
            case .travelled:
                postTripInsightView
            default:
                EmptyView()
            }
        }
        .onAppear {
            refreshLogic()
        }
        .onChange(of: travel.spots) { _ in refreshLogic() }
        .onChange(of: travel.statusRaw) { _ in refreshLogic() }
    }
    
    private func refreshLogic() {
        alerts = TravelLogicService.analyze(travel)
        activeFocus = TravelLogicService.getFocus(for: travel)
        if travel.status == .travelled {
            insight = TravelLogicService.generateInsight(for: travel)
        }
    }
    
    // MARK: - Planning Alerts (Pre-travel)
    
    private var planningAlertsView: some View {
        Group {
            if !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(TPDesign.leicaRed)
                        Text(locKey: "logic.plan.alert.title")
                            .font(TPDesign.overline())
                            .foregroundStyle(TPDesign.leicaRed)
                        Spacer()
                    }
                    
                    ForEach(alerts) { alert in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(alert.severity == .critical ? TPDesign.leicaRed : TPDesign.warmAmber)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(TPDesign.bodyFont(14, weight: .bold))
                                Text(alert.message)
                                    .font(TPDesign.captionFont())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(TPDesign.secondaryBackground)
                        .shadowSmall()
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(TPDesign.leicaRed.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Active Focus (During-travel)
    
    private var activeFocusView: some View {
        HStack(spacing: 16) {
            if let current = activeFocus.current {
                focusCard(title: "logic.active.now".localized, spot: current, isCurrent: true)
            }
            
            if let next = activeFocus.next {
                focusCard(title: "logic.active.next".localized, spot: next, isCurrent: false)
            } else if activeFocus.current == nil {
                // Empty state for active trip with no spots planned
                VStack(alignment: .leading) {
                    Text(locKey: "logic.active.empty")
                        .font(TPDesign.overline())
                        .foregroundStyle(.secondary)
                    Text(locKey: "logic.active.start_day")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TPDesign.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding(.horizontal)
    }
    
    private func focusCard(title: String, spot: Spot, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TPDesign.overline())
                .foregroundStyle(isCurrent ? Color.tpAccent : .secondary)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.tpAccent.opacity(0.1) : Color.gray.opacity(0.05))
                        .frame(width: 36, height: 36)
                    Image(systemName: spot.type.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isCurrent ? Color.tpAccent : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(TPDesign.bodyFont(15, weight: .bold))
                        .lineLimit(1)
                    
                    if let time = spot.estimatedDate {
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(TPDesign.captionFont())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(TPDesign.secondaryBackground)
                .shadowSmall()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isCurrent ? Color.tpAccent.opacity(0.2) : .clear, lineWidth: 1)
        )
    }
    
    // MARK: - Post Trip Insight (Post-travel)
    
    private var postTripInsightView: some View {
        Group {
            if let insight = insight {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locKey: "logic.post.title")
                                .font(TPDesign.editorialSerif(24))
                            Text(locKey: "logic.post.subtitle")
                                .font(TPDesign.bodyFont(14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "medal.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(TPDesign.warmAmber)
                    }
                    
                    HStack(spacing: 0) {
                        statView(label: "logic.stat.cost".localized, value: String(format: "¥%.0f", insight.totalCost))
                        Divider().padding(.vertical, 10)
                        statView(label: "logic.stat.distance".localized, value: String(format: "%.1f km", insight.distanceTravelled))
                        Divider().padding(.vertical, 10)
                        statView(label: "logic.stat.rate".localized, value: String(format: "%.0f%%", insight.completionRate * 100))
                    }
                    .padding(.vertical, 12)
                    .background(TPDesign.alabaster.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(TPDesign.secondaryBackground)
                        .shadowMedium()
                )
                .padding(.horizontal)
            }
        }
    }
    
    private func statView(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(TPDesign.obsidian)
        }
        .frame(maxWidth: .infinity)
    }
}
