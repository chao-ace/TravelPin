import SwiftUI

// MARK: - TripResonanceDetailView

struct TripResonanceDetailView: View {
    let trip: PublishedTrip
    let onRemix: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showRemixConfirm = false
    @State private var showComments = false
    @State private var isLiking = false

    var body: some View {
        ZStack {
            TPDesign.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    statsBar
                    interactionBar

                    if let snapshot = trip.decodedSnapshot {
                        itineraryTimeline(snapshot: snapshot)
                        spotGallery(snapshot: snapshot)
                        vibeSection(tags: snapshot.vibeTags)
                    } else {
                        snapshotUnavailable
                    }

                    Spacer(minLength: 140)
                }
            }
            .safeAreaInset(edge: .bottom) {
                remixActionBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComments) {
            CommentSheetView(trip: trip)
        }
        .task {
            await SocialService.shared.incrementViewCount(trip)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                cardGradient(for: trip.travelType)
                    .frame(height: 260)

                Image(systemName: trip.travelType.icon)
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

                Text(trip.title)
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(trip.travelType.displayName, systemImage: trip.travelType.icon)
                    Label("\(trip.durationDays) 天", systemImage: "calendar")
                    Label(trip.authorName, systemImage: "person.circle")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(28)
        }
    }

    private func cardGradient(for type: TravelType) -> LinearGradient {
        switch type {
        case .tourism:  return LinearGradient(colors: [TPDesign.deepNavy, TPDesign.midnightTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .concert:  return LinearGradient(colors: [TPDesign.marineDeep, TPDesign.celestialBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chill:    return LinearGradient(colors: [TPDesign.warmAmber.opacity(0.7), TPDesign.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business: return LinearGradient(colors: [TPDesign.obsidian, TPDesign.obsidian.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:    return LinearGradient(colors: [TPDesign.marineDeep.opacity(0.5), TPDesign.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(trip.durationDays)", label: "天", icon: "calendar")
            Divider().frame(height: 36)
            statCell(value: "\(trip.likeCount)", label: "喜欢", icon: "heart.fill")
            Divider().frame(height: 36)
            statCell(value: "\(trip.commentCount)", label: "评论", icon: "text.bubble")
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

    // MARK: - Interaction Bar

    private var interactionBar: some View {
        HStack(spacing: 0) {
            // Like
            Button {
                toggleLike()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: trip.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                    Text("\(trip.likeCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(trip.isLikedByCurrentUser ? .red : TPDesign.textSecondary)
                .frame(maxWidth: .infinity)
            }

            // Bookmark
            Button {
                toggleBookmark()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: trip.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                    Text("\(trip.bookmarkCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(trip.isBookmarkedByCurrentUser ? TPDesign.warmGold : TPDesign.textSecondary)
                .frame(maxWidth: .infinity)
            }

            // Comment
            Button {
                showComments = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 18))
                    Text("\(trip.commentCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(TPDesign.textSecondary)
                .frame(maxWidth: .infinity)
            }

            // Share
            ShareLink(item: "来看看这个旅程：\(trip.title)") {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                    Text("分享")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(TPDesign.textSecondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .cinematicFadeIn(delay: 0.15)
    }

    // MARK: - Itinerary Timeline

    private func itineraryTimeline(snapshot: TripSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("行程路线")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 28)

            ForEach(snapshot.itineraries.sorted(by: { $0.day < $1.day })) { itinerary in
                HStack(alignment: .top, spacing: 14) {
                    // Timeline node
                    VStack(spacing: 0) {
                        Text("D\(itinerary.day)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.tpAccent)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.tpAccent.opacity(0.1)))
                            .overlay(Circle().stroke(Color.tpAccent.opacity(0.2), lineWidth: 0.5))

                        if itinerary.day < (snapshot.itineraries.map(\.day).max() ?? 0) {
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

                        let daySpots = snapshot.spots.filter { _ in true } // All spots for simplicity
                        ForEach(daySpots.prefix(3)) { spot in
                            HStack(spacing: 8) {
                                Image(systemName: SpotType(rawValue: spot.typeRaw)?.icon ?? "mappin")
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

    private func spotGallery(snapshot: TripSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("足迹亮点")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(snapshot.spots) { spot in
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.tpAccent.opacity(0.05))
                                    .frame(width: 200, height: 140)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: SpotType(rawValue: spot.typeRaw)?.icon ?? "mappin")
                                                .font(.system(size: 28, weight: .light))
                                                .foregroundStyle(Color.tpAccent.opacity(0.2))
                                            Text(SpotType(rawValue: spot.typeRaw)?.displayName ?? "")
                                                .font(.system(size: 11))
                                                .foregroundStyle(TPDesign.textTertiary)
                                        }
                                    )
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

    private func vibeSection(tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("旅行氛围")
                .font(TPDesign.editorialSerif(22))
                .foregroundStyle(TPDesign.obsidian)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tags, id: \.self) { tag in
                        vibeTag(icon: tagIcon(tag), label: tag, color: tagColor(tag))
                    }
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

    private func tagIcon(_ tag: String) -> String {
        switch tag {
        case "摄影之旅":  return "camera.fill"
        case "自然风光":  return "leaf.fill"
        case "人文历史":  return "building.columns.fill"
        case "美食探索":  return "fork.knife"
        case "城市漫步":  return "figure.walk"
        case "海滨度假":  return "water.waves"
        case "山野徒步":  return "mountain.2"
        case "夜生活":    return "moon.stars.fill"
        default:         return "tag.fill"
        }
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "摄影之旅":  return TPDesign.celestialBlue
        case "自然风光":  return .green
        case "人文历史":  return TPDesign.warmAmber
        case "美食探索":  return .orange
        case "城市漫步":  return .purple
        case "海滨度假":  return .cyan
        case "山野徒步":  return .brown
        case "夜生活":    return .indigo
        default:         return TPDesign.textSecondary
        }
    }

    // MARK: - Snapshot Unavailable

    private var snapshotUnavailable: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(TPDesign.textTertiary)
            Text("详细行程数据暂不可用")
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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

    // MARK: - Actions

    private func toggleLike() {
        guard !isLiking else { return }
        isLiking = true
        TPHaptic.selection()
        Task {
            await SocialService.shared.toggleLike(trip)
            isLiking = false
        }
    }

    private func toggleBookmark() {
        TPHaptic.selection()
        Task {
            await SocialService.shared.toggleBookmark(trip)
        }
    }
}

#Preview {
    NavigationStack {
        let sample = PublishedTrip(
            originalTravelId: nil,
            authorName: "Explorer",
            title: "Paris Architecture Tour",
            descriptionText: "A beautiful tour",
            coverGradientRaw: "deepNavy",
            categoryTags: ["Culture", "Architecture"],
            travelTypeRaw: "Tourism",
            durationDays: 5
        )
        TripResonanceDetailView(trip: sample) {}
    }
}
