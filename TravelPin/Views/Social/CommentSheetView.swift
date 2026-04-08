import SwiftUI

// MARK: - CommentSheetView

struct CommentSheetView: View {
    let trip: PublishedTrip
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [SocialInteraction] = []
    @State private var newComment: String = ""
    @State private var isLoading = false
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 60)
                        Spacer()
                    } else if comments.isEmpty {
                        emptyState
                        Spacer()
                    } else {
                        commentList
                    }

                    commentInputBar
                }
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(TPDesign.textSecondary)
                }
            }
        }
        .task {
            await loadComments()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "text.bubble")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(TPDesign.textTertiary)
            Text("还没有评论")
                .font(TPDesign.bodyFont(16))
                .foregroundStyle(TPDesign.textTertiary)
            Text("成为第一个分享想法的人")
                .font(TPDesign.bodyFont(13))
                .foregroundStyle(TPDesign.textTertiary.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Comment List

    private var commentList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
            .padding(20)
        }
    }

    private func commentRow(_ comment: SocialInteraction) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.tpAccent.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: comment.authorAvatarSymbol)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.tpAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(TPDesign.obsidian)
                    Text(comment.createdAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(TPDesign.textTertiary)
                }

                if let content = comment.content {
                    Text(content)
                        .font(TPDesign.bodyFont(15))
                        .foregroundStyle(TPDesign.textPrimary)
                        .lineSpacing(4)
                }
            }

            Spacer()
        }
    }

    // MARK: - Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 12) {
                TextField("写下你的想法...", text: $newComment, axis: .vertical)
                    .font(TPDesign.bodyFont(15))
                    .lineLimit(1...4)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
                    )

                Button {
                    sendComment()
                } label: {
                    ZStack {
                        Circle()
                            .fill(newComment.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(TPDesign.obsidian.opacity(0.15)) : AnyShapeStyle(TPDesign.accentGradient))
                            .frame(width: 36, height: 36)
                        if isSending {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.9))
        }
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await SocialService.shared.fetchComments(for: trip.id)
        } catch {
            print("[CommentSheet] Load failed: \(error)")
        }
        isLoading = false
    }

    private func sendComment() {
        let content = newComment.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        isSending = true
        TPHaptic.selection()

        Task {
            do {
                try await SocialService.shared.postComment(trip, content: content)
                newComment = ""
                await loadComments()
            } catch {
                print("[CommentSheet] Send failed: \(error)")
            }
            isSending = false
        }
    }
}
