import ActivityKit
import WidgetKit
import SwiftUI

struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // Lock Screen UI
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.tripName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        Text(context.state.currentSpotName)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                    }
                    
                    Spacer()
                    
                    if let temp = context.state.temperature {
                        Text("\(Int(temp))°C")
                            .font(.system(size: 20, weight: .medium))
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                HStack {
                    if let next = context.state.nextSpotName {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("下一站")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(next)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        if let dist = context.state.distanceToNext {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("相距")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f km", dist))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(red: 0.82, green: 0.01, blue: 0.11)) // Leica Red
                            }
                        }
                    } else {
                        Text("旅程进行中...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.white.opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.currentSpotName, systemImage: "mappin.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.82, green: 0.01, blue: 0.11))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let temp = context.state.temperature {
                        Text("\(Int(temp))°C")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let next = context.state.nextSpotName, let dist = context.state.distanceToNext {
                            Text("下一站: \(next)")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1f km", dist))
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color(red: 0.82, green: 0.01, blue: 0.11))
                        } else {
                            Text(context.attributes.tripName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 10)
                }
            } compactLeading: {
                Image(systemName: "airplane")
                    .foregroundStyle(Color(red: 0.82, green: 0.01, blue: 0.11))
            } compactTrailing: {
                if let dist = context.state.distanceToNext {
                    Text(String(format: "%.0f km", dist))
                        .font(.system(size: 10, weight: .bold))
                }
            } minimal: {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color(red: 0.82, green: 0.01, blue: 0.11))
            }
        }
    }
}
