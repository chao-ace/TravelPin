import SwiftUI

// MARK: - CollaborationActivityView

struct CollaborationActivityView: View {
    @ObservedObject var realtime = RealtimeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                if realtime.activityLog.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(TPDesign.textTertiary)
                        Text("暂无协作动态")
                            .font(TPDesign.bodyFont(15))
                            .foregroundStyle(TPDesign.textTertiary)
                        Text("当协作者编辑行程时，动态会在这里实时显示")
                            .font(TPDesign.bodyFont(13))
                            .foregroundStyle(TPDesign.textTertiary.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(realtime.activityLog) { entry in
                                activityRow(entry)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("协作动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func activityRow(_ entry: ActivityEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(activityColor(for: entry.event).opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.eventIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(activityColor(for: entry.event))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayText)
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textPrimary)
                    .lineSpacing(3)

                Text(entry.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11))
                    .foregroundStyle(TPDesign.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private func activityColor(for event: String) -> Color {
        switch event {
        case "add":      return Color.tpAccent
        case "edit":     return TPDesign.celestialBlue
        case "delete":   return TPDesign.warmAmber
        case "complete": return Color.tpAccent
        default:         return TPDesign.textSecondary
        }
    }
}
