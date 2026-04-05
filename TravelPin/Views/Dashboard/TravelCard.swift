import SwiftUI

struct TravelCard: View {
    let travel: Travel

    var body: some View {
        HStack(spacing: 16) {
            // Icon / Status Circle
            ZStack {
                Circle()
                    .fill(Color.statusColor(for: travel.status).opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: travel.type.icon)
                    .font(.title2)
                    .foregroundStyle(Color.statusColor(for: travel.status))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(travel.name)
                    .font(TPDesign.titleFont(20))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("\(travel.startDate.formatted(.dateTime.month().day())) - \(travel.endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Status Tag
            Text(travel.status.displayName)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.statusColor(for: travel.status).opacity(0.1))
                .foregroundStyle(Color.statusColor(for: travel.status))
                .clipShape(Capsule())
        }
        .padding()
        .glassCard()
    }
}
