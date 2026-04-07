import SwiftUI
import SwiftData

struct TravelCard: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext
    @State private var showingDatePicker = false
    @State private var isPressed = false
    @State private var offset: CGFloat = 0

    private var statusColor: Color {
        Color.statusColor(for: travel.status)
    }

    private var firstSpotPhoto: UIImage? {
        guard let firstSpot = travel.spots.first,
              let photo = firstSpot.photos.first,
              let data = photo.data else {
            return nil
        }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete Action Surface
            Group {
                if offset < 0 {
                    Rectangle()
                        .fill(Color.red)
                        .overlay(
                            Image(systemName: "trash")
                                .foregroundStyle(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.trailing, 24),
                            alignment: .trailing
                        )
                        .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 18, topTrailingRadius: 18))
                        .frame(width: max(0, -offset))
                        .onTapGesture {
                            withAnimation {
                                modelContext.delete(travel)
                                try? modelContext.save()
                                TPHaptic.notification(.success)
                            }
                        }
                }
            }

            HStack(spacing: 0) {
                // Left accent stripe — status color
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14))

                HStack(spacing: TPDesign.spacing20) {
                    // Left: Visual Portal
                    ZStack {
                        if let uiImage = firstSpotPhoto {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    LinearGradient(
                                        colors: [.black.opacity(0.08), .clear],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(statusColor.opacity(0.08))
                                .frame(width: 64, height: 64)

                            Image(systemName: travel.type.icon)
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(statusColor)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 0.3)
                    )
                    .shadowSmall()

                    // Center: Typographic Core
                    VStack(alignment: .leading, spacing: TPDesign.spacing4) {
                        Text(travel.name)
                            .font(TPDesign.editorialSerif(18))
                            .foregroundStyle(TPDesign.obsidian)
                            .lineLimit(1)

                        Button {
                            TPHaptic.selection()
                            showingDatePicker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: TPDesign.spacing4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("\(travel.startDate.formatted(.dateTime.day().month())) - \(travel.endDate.formatted(.dateTime.day().month()))")
                                        .font(TPDesign.captionFont())
                                }
                                .foregroundStyle(TPDesign.textTertiary)
                                .trackingMedium()
                                
                                TravelingCountdown(startDate: travel.startDate)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Right: Zen Status Indicator
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(travel.status.displayName.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .tracking(1.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.08))
                            .foregroundStyle(statusColor)
                            .clipShape(Capsule())

                        Circle()
                            .fill(statusColor)
                            .frame(width: 4, height: 4)
                            .padding(.trailing, 4)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                    .fill(TPDesign.alabaster) // Explicitly white/alabaster base
                    .overlay(.ultraThinMaterial) // Layer blur on top of white
                    .overlay(
                        RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .liquidShimmer()
            )
            .offset(x: offset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        if offset == 0 && gesture.translation.width < 0 {
                            offset = max(gesture.translation.width, -80)
                        } else if offset < 0 {
                            offset = min(-80 + gesture.translation.width, 0)
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if gesture.translation.width < -40 {
                                offset = -80
                            } else if gesture.translation.width > 30 {
                                offset = 0
                            } else {
                                offset = offset < -40 ? -80 : 0
                            }
                        }
                    }
            )
        }
        .compositingGroup()
        .shadowMedium()
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            withAnimation(.interactiveSpring()) {
                isPressed = pressing
            }
        }, perform: {})
        .popover(isPresented: $showingDatePicker) {
            datePickerPopover
        }
    }

    private var datePickerPopover: some View {
        VStack(spacing: 24) {
            Text("edit.travel.dates".localized)
                .font(TPDesign.editorialSerif(24))
                .padding(.top)

            DatePicker("edit.travel.start".localized, selection: $travel.startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)

            DatePicker("edit.travel.end".localized, selection: $travel.endDate, in: travel.startDate..., displayedComponents: .date)
                .datePickerStyle(.compact)

            Button(action: {
                TPHaptic.notification(.success)
                showingDatePicker = false
            }) {
                Text("common.done".localized)
                    .font(TPDesign.bodyFont())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TPDesign.accentGradient)
                    .clipShape(Capsule())
            }
            .padding(.bottom)
        }
        .padding(24)
        .frame(width: 340)
        .background(TPDesign.isabelline)
    }
}
