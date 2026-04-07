//
//  TravelPinWidget.swift
//  TravelPinWidget
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data (read from App Group UserDefaults)

struct WidgetTripData {
    let tripName: String
    let daysUntil: Int
    let totalTrips: Int
    let totalSpots: Int
    let status: String

    static func load() -> WidgetTripData {
        let defaults = UserDefaults(suiteName: "group.com.travelpin.app")
        return WidgetTripData(
            tripName: defaults?.string(forKey: "widget_tripName") ?? "暂无计划",
            daysUntil: defaults?.integer(forKey: "widget_daysUntil") ?? 0,
            totalTrips: defaults?.integer(forKey: "widget_totalTrips") ?? 0,
            totalSpots: defaults?.integer(forKey: "widget_totalSpots") ?? 0,
            status: defaults?.string(forKey: "widget_status") ?? "Planning"
        )
    }
}

// MARK: - Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "旅行倒计时")]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

// MARK: - Widget Colors

private let brandBlue = Color(red: 0.30, green: 0.65, blue: 0.96)
private let deepBlue = Color(red: 0.10, green: 0.45, blue: 0.85)
private let obsidian = Color(red: 0.08, green: 0.08, blue: 0.09)

// MARK: - Entry View

struct TravelPinWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let data = WidgetTripData.load()

        switch family {
        case .systemSmall:
            smallWidget(data: data)
        case .systemMedium:
            mediumWidget(data: data)
        default:
            smallWidget(data: data)
        }
    }

    // MARK: - Small Widget

    private func smallWidget(data: WidgetTripData) -> some View {
        ZStack {
            LinearGradient(
                colors: [brandBlue, deepBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))

                if data.daysUntil > 0 {
                    Text("\(data.daysUntil)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("天后出发")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                } else if data.daysUntil == 0 {
                    Text("今天!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("出发日")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("\(data.totalTrips)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("个旅程记录")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }

    // MARK: - Medium Widget

    private func mediumWidget(data: WidgetTripData) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.96, blue: 0.94), .white],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 14) {
                // Left: Countdown Circle
                ZStack {
                    Circle()
                        .stroke(brandBlue.opacity(0.15), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: data.daysUntil > 0 ? min(CGFloat(data.daysUntil) / 30.0, 1.0) : 1.0)
                        .stroke(brandBlue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        if data.daysUntil > 0 {
                            Text("\(data.daysUntil)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(brandBlue)
                            Text("天")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "airplane")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(brandBlue)
                        }
                    }
                }
                .frame(width: 70, height: 70)

                // Right: Trip Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("下一次旅程")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    Text(data.tripName)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(obsidian)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        Label("\(data.totalTrips) 旅程", systemImage: "map.fill")
                        Label("\(data.totalSpots) 足迹", systemImage: "mappin")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
        }
    }
}

// MARK: - Widget Configuration

struct TravelPinWidget: Widget {
    let kind: String = "TravelPinCountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TravelPinWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("旅行倒计时")
        .description("查看下一次旅行的倒计时和统计")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#if os(iOS)
#Preview(as: .systemSmall) {
    TravelPinWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent())
}
#endif
