import SwiftUI
import SwiftData

// MARK: - Export Format

enum PosterExportFormat: String, CaseIterable, Identifiable {
    case xiaohongshu = "poster.format.xiaohongshu"
    case moments = "poster.format.moments"
    case landscape = "poster.format.landscape"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xiaohongshu: return "小红书卡片"
        case .moments:     return "朋友圈动态"
        case .landscape:   return "全景海报"
        }
    }

    var ratio: CGFloat {
        switch self {
        case .xiaohongshu: return 3.0 / 4.0   // 1080×1440
        case .moments:     return 1.0           // 1080×1080
        case .landscape:   return 16.0 / 9.0   // 1920×1080
        }
    }

    var pixelSize: CGSize {
        switch self {
        case .xiaohongshu: return CGSize(width: 1080, height: 1440)
        case .moments:     return CGSize(width: 1080, height: 1080)
        case .landscape:   return CGSize(width: 1920, height: 1080)
        }
    }
}

// MARK: - Poster Renderer

struct PosterRenderer {
    /// Render a TripPosterView to UIImage at the specified format
    @MainActor
    static func render(travel: Travel, format: PosterExportFormat) -> UIImage? {
        let poster = Group {
            switch format {
            case .xiaohongshu:
                XiaohongshuPoster(travel: travel)
            case .moments:
                MomentsPoster(travel: travel)
            case .landscape:
                TripPosterView(travel: travel)
            }
        }

        let renderer = ImageRenderer(content: poster)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

// MARK: - Xiaohongshu Poster (3:4 Vertical)

struct XiaohongshuPoster: View {
    let travel: Travel

    var body: some View {
        VStack(spacing: 0) {
            // Hero Image Area (top 40%)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.tpAccent, Color.tpAccent.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // If there's a cover photo, use it
                if let firstSpot = travel.spots.first(where: { !$0.photos.isEmpty }),
                   let photo = firstSpot.photos.first,
                   let data = photo.data,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(travel.name)
                        .font(.system(size: 40, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        Label("\(travel.itineraries.count) 天", systemImage: "calendar")
                        Label("\(travel.spots.count) 处足迹", systemImage: "mappin.and.ellipse")
                        Text(travel.type.displayName)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(30)
            }
            .frame(height: 576) // 40% of 1440

            // Photo Grid (middle section)
            let photoSpots = travel.spots.filter { !$0.photos.isEmpty }

            if !photoSpots.isEmpty {
                LazyVGrid(
                    columns: photoSpots.count >= 4
                        ? [GridItem(.flexible()), GridItem(.flexible())]
                        : [GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(photoSpots.prefix(4)) { spot in
                        if let photo = spot.photos.first,
                           let data = photo.data,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            // Stats Bar
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text(formatDate(travel.startDate))
                    Text("出发日期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 16, weight: .bold))

                Spacer()

                VStack(spacing: 4) {
                    Text(formatDate(travel.endDate))
                    Text("结束日期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 16, weight: .bold))
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)

            Spacer()

            // Footer
            HStack {
                Label("TravelPin", systemImage: "pencil.and.outline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("记录你的每一段不凡旅程")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(Color.tpSurface)
        }
        .frame(width: 1080, height: 1440)
        .background(.white)
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day())
    }

    private func travelTypeEmoji(_ type: String) -> String {
        switch type.lowercased() {
        case "tourism": return "✈️ 出游"
        case "concert": return "🎵 演唱会"
        case "chill": return "🏖 散心"
        case "business": return "💼 出差"
        default: return "🗺 旅行"
        }
    }
}

// MARK: - Moments Poster (1:1 Square)

struct MomentsPoster: View {
    let travel: Travel

    var body: some View {
        ZStack {
            // Background
            if let firstSpot = travel.spots.first(where: { !$0.photos.isEmpty }),
               let photo = firstSpot.photos.first,
               let data = photo.data,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 1080, height: 1080)
                    .clipped()
                    .blur(radius: 2)
                    .overlay(Color.black.opacity(0.4))
            } else {
                LinearGradient(
                    colors: [Color.tpAccent, Color.tpAccent.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            VStack(spacing: 30) {
                Spacer()

                Text(travel.name)
                    .font(.system(size: 52, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("\(travel.itineraries.count) 天 · \(travel.spots.count) 处足迹")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(travel.startDate.formatted(.dateTime.year().month().day())) — \(travel.endDate.formatted(.dateTime.year().month().day()))")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Photo strip
                if !travel.spots.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(travel.spots.prefix(3)) { spot in
                            Group {
                                if let photo = spot.photos.first, let data = photo.data, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Rectangle().fill(.white.opacity(0.2))
                                }
                            }
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }

                Spacer()

                Text("TravelPin")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(40)
        }
        .frame(width: 1080, height: 1080)
    }
}

// MARK: - Export Sheet

struct PosterExportSheet: View {
    let travel: Travel
    @State private var selectedFormat: PosterExportFormat = .xiaohongshu
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Format Picker
                Picker("poster.export.format".localized, selection: $selectedFormat) {
                    ForEach(PosterExportFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Preview
                Group {
                    if let image = renderedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.quaternary.opacity(0.3))
                            .overlay(
                        VStack(spacing: 12) {
                                    ProgressView()
                                    Text("渲染中...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                }
                .frame(maxHeight: 400)
                .padding(.horizontal)

                // Actions
                HStack(spacing: 16) {
                    if let image = renderedImage {
                        Button {
                            shareImage(image)
                        } label: {
                            Label("分享海报", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.tpAccent)

                        Button {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        } label: {
                            Label("保存到相册", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("导出海报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                await renderPoster()
            }
            .onChange(of: selectedFormat) { _, _ in
                Task { await renderPoster() }
            }
        }
    }

    @MainActor
    private func renderPoster() async {
        isRendering = true
        renderedImage = nil
        try? await Task.sleep(for: .milliseconds(100))
        renderedImage = PosterRenderer.render(travel: travel, format: selectedFormat)
        isRendering = false
    }

    private func shareImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(activityVC, animated: true)
    }
}
