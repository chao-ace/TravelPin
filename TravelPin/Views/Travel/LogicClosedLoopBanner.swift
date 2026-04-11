import SwiftUI
import SwiftData
import Combine

/// A logic-driven banner system that adapts to the travel lifecycle:
/// - Pre-travel: Shows logical conflicts and planning alerts with fix actions.
/// - During-travel: Shows a rich NowPlaying card with real-time guidance.
/// - Post-travel: Shows a summary of the trip's achievements with template reuse.
struct LogicClosedLoopBanner: View {
    let travel: Travel

    @State private var alerts: [TravelLogicService.LogicAlert] = []
    @State private var activeFocus: (current: Spot?, next: Spot?) = (nil, nil)
    @State private var insight: TravelLogicService.TripInsight? = nil
    @State private var nowState: NowState? = nil
    @State private var selectedFix: ScheduleFix? = nil
    @State private var template: TripTemplate? = nil
    @State private var refreshTimer: Timer.TimerPublisher = Timer.publish(every: 60, on: .main, in: .common)

    var body: some View {
        Group {
            switch travel.status {
            case .planning, .wishing:
                planningAlertsView
            case .traveling:
                if let state = nowState {
                    NowPlayingCard(state: state, travel: travel)
                } else {
                    // Loading shimmer
                    RoundedRectangle(cornerRadius: 24)
                        .fill(TPDesign.secondaryBackground)
                        .frame(height: 120)
                        .shimmer()
                        .padding(.horizontal)
                }
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
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            if travel.status == .traveling {
                refreshNowState()
            }
        }
        .sheet(item: $selectedFix) { fix in
            ScheduleFixSheet(fix: fix, travel: travel)
        }
    }

    private func refreshLogic() {
        alerts = TravelLogicService.analyze(travel)
        activeFocus = TravelLogicService.getFocus(for: travel)
        if travel.status == .travelled {
            insight = TravelLogicService.generateInsight(for: travel)
            template = TravelLogicService.generateTemplate(from: travel)
        }
        if travel.status == .traveling {
            refreshNowState()
        }
    }

    private func refreshNowState() {
        Task {
            nowState = await TravelLogicService.getNowState(for: travel)
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

                    let fixes = TravelLogicService.suggestFixes(for: travel, alerts: alerts)

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

                            Spacer()

                            // Fix button
                            if let fix = fixes.first(where: { $0.alertTitle == alert.title }) {
                                Button {
                                    selectedFix = fix
                                } label: {
                                    Text(locKey: "logic.fix.action")
                                        .font(TPDesign.captionFont())
                                        .foregroundStyle(Color.tpAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.tpAccent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
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

                    // Success metrics & "Plan Similar" button
                    if let tmpl = template {
                        successMetricsCard(template: tmpl)

                        CinematicPrimaryButton(
                            locKey: "logic.post.similar",
                            icon: "arrow.triangle.branch"
                        ) {
                            planSimilarTrip(from: tmpl)
                        }
                    }
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

    private func successMetricsCard(template: TripTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(locKey: "logic.post.metrics")
                .font(TPDesign.overline())
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                metricBadge(
                    icon: "checkmark.circle.fill",
                    label: String(format: "%.0f%%", template.successMetrics.completionRate * 100),
                    subtitle: "logic.metric.completion".localized,
                    color: template.successMetrics.completionRate >= 0.7 ? .green : .orange
                )

                if let util = template.successMetrics.budgetUtilization {
                    metricBadge(
                        icon: "yensign.circle.fill",
                        label: String(format: "%.0f%%", util * 100),
                        subtitle: "logic.metric.budget".localized,
                        color: util <= 1.0 ? .green : TPDesign.leicaRed
                    )
                }

                if let avg = template.successMetrics.avgRating {
                    metricBadge(
                        icon: "star.fill",
                        label: String(format: "%.1f", avg),
                        subtitle: "logic.metric.rating".localized,
                        color: TPDesign.warmAmber
                    )
                }
            }
        }
    }

    private func metricBadge(icon: String, label: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 16, weight: .black, design: .rounded))
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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

    private func planSimilarTrip(from template: TripTemplate) {
        guard let modelContext = travel.modelContext else { return }
        let newTravel = Travel(
            name: String(format: "logic.post.similar_name".localized, template.name),
            startDate: Date().addingTimeInterval(86400.0 * 7),
            endDate: Date().addingTimeInterval(86400.0 * Double(7 + template.durationDays)),
            status: TravelStatus.planning.rawValue,
            type: template.type.rawValue
        )
        newTravel.budget = template.budget
        newTravel.currency = template.currency
        modelContext.insert(newTravel)
        try? modelContext.processPendingChanges()
        try? modelContext.save()
        TPHaptic.notification(.success)
    }
}
