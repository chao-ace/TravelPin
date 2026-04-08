import SwiftUI
import SwiftData

// MARK: - PublishTripView

struct PublishTripView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isPublishing = false
    @State private var showSuccess = false

    private let availableTags = ["自然风光", "人文历史", "美食探索", "摄影之旅", "城市漫步", "海滨度假", "山野徒步", "夜生活"]

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        previewCard
                        titleSection
                        descriptionSection
                        tagsSection
                        publishButton

                        Spacer(minLength: 60)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("发布到灵感广场")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(TPDesign.textSecondary)
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
        .onAppear {
            title = travel.name
            description = "一场\(travel.durationDays)天的\(travel.type.displayName)之旅"
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预览")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardGradient(for: travel.type))
                        .frame(width: 80, height: 80)
                    Image(systemName: travel.type.icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(travel.name)
                        .font(TPDesign.editorialSerif(18))
                        .foregroundStyle(TPDesign.obsidian)
                    HStack(spacing: 12) {
                        Label("\(travel.durationDays) 天", systemImage: "calendar")
                        Label("\(travel.spots.count) 处足迹", systemImage: "mappin")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(TPDesign.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(TPDesign.secondaryBackground.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
            )
            .shadowSmall()
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标题")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
            TextField("给你的旅程起个标题", text: $title)
                .font(TPDesign.bodyFont(17, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(TPDesign.secondaryBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
                )
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("描述")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)
            TextEditor(text: $description)
                .font(TPDesign.bodyFont(15))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(TPDesign.secondaryBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
                )
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类标签")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)

            FlowLayout(spacing: 10) {
                ForEach(availableTags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        TPHaptic.selection()
                        withAnimation(.spring(response: 0.3)) {
                            if isSelected {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            Text(tag)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? .white : TPDesign.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule().fill(TPDesign.accentGradient)
                            } else {
                                Capsule().fill(TPDesign.secondaryBackground)
                            }
                        }
                        .overlay(Capsule().stroke(isSelected ? Color.clear : TPDesign.divider, lineWidth: 0.5))
                    }
                    .buttonStyle(CinematicButtonStyle())
                }
            }
        }
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button {
            publishTrip()
        } label: {
            HStack(spacing: 10) {
                if isPublishing {
                    ProgressView()
                        .tint(.white)

                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(isPublishing ? "发布中..." : "发布到灵感广场")
                    .font(TPDesign.bodyFont(17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule().fill(title.isEmpty ? AnyShapeStyle(TPDesign.obsidian.opacity(0.3)) : AnyShapeStyle(TPDesign.accentGradient))
            )
            .shadowLarge()
        }
        .disabled(title.isEmpty || isPublishing)
        .buttonStyle(CinematicButtonStyle())
        .padding(.top, 8)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(TPDesign.accentGradient)
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("发布成功！")
                    .font(TPDesign.editorialSerif(24))
                    .foregroundStyle(TPDesign.obsidian)
                Text("你的旅程已分享到灵感广场")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textSecondary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(TPDesign.secondaryBackground)
                    .shadowFloating()
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func cardGradient(for type: TravelType) -> LinearGradient {
        switch type {
        case .tourism:  return LinearGradient(colors: [TPDesign.deepNavy, TPDesign.midnightTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .concert:  return LinearGradient(colors: [TPDesign.marineDeep, TPDesign.celestialBlue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chill:    return LinearGradient(colors: [TPDesign.warmAmber.opacity(0.6), TPDesign.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business: return LinearGradient(colors: [TPDesign.obsidian, TPDesign.obsidian.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:    return LinearGradient(colors: [TPDesign.marineDeep.opacity(0.5), TPDesign.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func publishTrip() {
        guard !title.isEmpty else { return }
        isPublishing = true
        TPHaptic.notification(.success)

        Task {
            do {
                try await SocialService.shared.publishTrip(
                    travel,
                    title: title,
                    description: description,
                    categoryTags: Array(selectedTags)
                )
                withAnimation(.spring(response: 0.5)) {
                    showSuccess = true
                }
            } catch {
                print("[PublishTripView] Failed: \(error)")
            }
            isPublishing = false
        }
    }
}

// MARK: - FlowLayout (Tag wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
