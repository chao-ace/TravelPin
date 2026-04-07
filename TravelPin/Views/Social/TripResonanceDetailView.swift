import SwiftUI
import SwiftData

struct TripResonanceDetailView: View {
    let travel: Travel
    let onRemix: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showRemixConfirm = false

    var body: some View {
        ZStack {
            TPDesign.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    statsBar
                    itineraryTimeline
                    spotGallery
                    vibeSection

                    Spacer(minLength: 140)
                }
            }
            .safeAreaInset(edge: .bottom) {
                remixActionBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient backdrop
            ZStack {
                cardGradient(for: travel.type)
                    .frame(height: 260)

                // Decorative
                Image(systemName: travel.type.icon)
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.06))
                    .offset(x: 100, y: -40)
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("社区灵感")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(TPDesign.warmGold)
                .tracking(1)

                Text(travel.name)
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(travel.type.displayName, systemImage: travel.type.icon)
                    Label("\(travel.durationDays) 天", systemImage: "calendar")
                    Text(travel.startDate.formatted(.dateTime.year().month()))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(28)
        }
    }

    private func cardGradient(for type: TravelType) -> LinearGradient {
        switch type {
        case .tourism: return LinearGradient(colors: [TPDesign.deepNavy, TPDesign.midnightTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .concert: return LinearGradient(colors: [TPDesign.marineDeep, TPDesign.celestialBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chill: return LinearGradient(colors: [TPDesign.warmAmber.opacity(0.7), TPDesign.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business: return LinearGradient(colors: [TPDesign.obsidian, TPDesign.obsidian.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other: return LinearGradient(colors: [TPDesign.marineDeep.opacity(0.5), TPDesign.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(travel.itineraries.count)", label: "天", icon: "calendar")
            Divider().frame(height: 36)
            statCell(value: "\(travel.spots.count)", label: "处足迹", icon: "mappin")
            Divider().frame(height: 36)
            statCell(value: "\(travel.spots.filter { $0.type == .food }.count)", label: "美食", icon: "fork.knife")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadowSmall()
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .cinematicFadeIn(delay: 0.1)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(TPDesign.obsidian)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Itinerary Timeline

    private var itineraryTimeline: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("行程路线")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 28)

            ForEach(travel.itineraries.sorted(by: { $0.day < $1.day })) { itinerary in
                HStack(alignment: .top, spacing: 14) {
                    // Timeline node
                    VStack(spacing: 0) {
                        Text("D\(itinerary.day)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.tpAccent)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.tpAccent.opacity(0.1)))
                            .overlay(Circle().stroke(Color.tpAccent.opacity(0.2), lineWidth: 0.5))

                        if itinerary.day < (travel.itineraries.map(\.day).max() ?? 0) {
                            Rectangle()
                                .fill(Color.tpAccent.opacity(0.1))
                                .frame(width: 1.5)
                                .frame(minHeight: 40)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(itinerary.origin) → \(itinerary.destination)")
                            .font(TPDesign.bodyFont(16, weight: .bold))
                            .foregroundStyle(TPDesign.textPrimary)

                        let daySpots = travel.spots.filter { $0.itinerary?.persistentModelID == itinerary.persistentModelID }
                            .sorted { $0.sequence < $1.sequence }
                        
                        ForEach(daySpots) { spot in
                            HStack(spacing: 8) {
                                Image(systemName: spot.type.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.tpAccent)
                                Text(spot.name)
                                    .font(TPDesign.bodyFont(14))
                                    .foregroundStyle(TPDesign.textSecondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
            }
        }
        .cinematicFadeIn(delay: 0.2)
    }

    // MARK: - Spot Gallery

    private var spotGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("足迹亮点")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(travel.spots) { spot in
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.tpAccent.opacity(0.05))
                                    .frame(width: 200, height: 140)
                                    
                                if let photo = spot.photos.first, let data = photo.data, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: spot.type.icon)
                                            .font(.system(size: 28, weight: .light))
                                            .foregroundStyle(Color.tpAccent.opacity(0.2))
                                        Text(spot.type.displayName)
                                            .font(.system(size: 11))
                                            .foregroundStyle(TPDesign.textTertiary)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(spot.name)
                                    .font(TPDesign.cardTitle())
                                    .foregroundStyle(TPDesign.textPrimary)
                                    .lineLimit(1)
                                if !spot.notes.isEmpty {
                                    Text(spot.notes)
                                        .font(.system(size: 12))
                                        .foregroundStyle(TPDesign.textTertiary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .cinematicFadeIn(delay: 0.3)
    }

    // MARK: - Vibe Section

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("旅行氛围")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    vibeTag(icon: "camera.fill", label: "摄影之旅", color: TPDesign.celestialBlue)
                    vibeTag(icon: "leaf.fill", label: "自然风光", color: .green)
                    vibeTag(icon: "building.columns.fill", label: "人文历史", color: TPDesign.warmAmber)
                    vibeTag(icon: "fork.knife", label: "美食探索", color: .orange)
                }
                .padding(.horizontal, 24)
            }
        }
        .cinematicFadeIn(delay: 0.35)
    }

    private func vibeTag(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(color.opacity(0.08)))
        .overlay(Capsule().stroke(color.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Floating Action Bar

    private var remixActionBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            Button {
                showRemixConfirm = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("将此旅程 Remix 到我的计划")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(TPDesign.accentGradient)
                .clipShape(Capsule())
                .shadowLarge()
            }
            .buttonStyle(CinematicButtonStyle())
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.white.opacity(0.85))
        }
        .confirmationDialog("将此旅程添加到你的计划？", isPresented: $showRemixConfirm) {
            Button("确认 Remix") {
                TPHaptic.notification(.success)
                onRemix()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将复制一份旅程副本到你的账户，包含行程和景点信息")
        }
    }
}

#Preview {
    NavigationStack {
        TripResonanceDetailView(travel: MockDataCenter.getPublicTrips().first!) {
            // remix action
        }
    }
}
