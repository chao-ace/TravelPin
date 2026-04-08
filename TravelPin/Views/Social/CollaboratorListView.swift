import SwiftUI

// MARK: - CollaboratorListView

struct CollaboratorListView: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var realtime = RealtimeManager.shared
    @State private var showInviteSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        onlineSection
                        allCollaboratorsSection
                        Spacer(minLength: 60)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("协作者")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.tpAccent)
                    }
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                // Inline mini invite generator
                QuickInviteSheet(travel: travel)
            }
        }
    }

    // MARK: - Online Section

    private var onlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("在线 (\(realtime.onlineUsers.count))")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
            }

            if realtime.onlineUsers.isEmpty {
                Text("暂无其他协作者在线")
                    .font(TPDesign.bodyFont(14))
                    .foregroundStyle(TPDesign.textTertiary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(realtime.onlineUsers.keys), id: \.self) { userId in
                    HStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.tpAccent.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.tpAccent)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(TPDesign.background, lineWidth: 2))
                        }

                        Text(realtime.onlineUsers[userId] ?? "Unknown")
                            .font(TPDesign.bodyFont(15, weight: .medium))
                            .foregroundStyle(TPDesign.obsidian)

                        Spacer()

                        Text("编辑中")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.tpAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.tpAccent.opacity(0.1)))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(TPDesign.secondaryBackground.opacity(0.6))
                    )
                }
            }
        }
    }

    // MARK: - All Collaborators

    private var allCollaboratorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("所有成员")
                .font(TPDesign.overline())
                .foregroundStyle(TPDesign.textTertiary)

            // Owner (always the current user)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TPDesign.warmGold.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(TPDesign.warmGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("你")
                        .font(TPDesign.bodyFont(15, weight: .semibold))
                        .foregroundStyle(TPDesign.obsidian)
                    Text("创建者")
                        .font(.system(size: 12))
                        .foregroundStyle(TPDesign.textTertiary)
                }

                Spacer()

                Text("Owner")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TPDesign.warmGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(TPDesign.warmGold.opacity(0.1)))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.6))
            )

            // Companion names from Travel model
            ForEach(travel.companionNames, id: \.self) { name in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.tpAccent.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.tpAccent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(TPDesign.bodyFont(15, weight: .semibold))
                            .foregroundStyle(TPDesign.obsidian)
                        Text("可编辑")
                            .font(.system(size: 12))
                            .foregroundStyle(TPDesign.textTertiary)
                    }

                    Spacer()

                    Menu {
                        Button("设为仅查看") {
                            TPHaptic.selection()
                        }
                        Button("移除成员", role: .destructive) {
                            TPHaptic.selection()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(TPDesign.textTertiary)
                            .padding(8)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.6))
                )
            }
        }
    }
}

// MARK: - QuickInviteSheet

private struct QuickInviteSheet: View {
    let travel: Travel
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode: String?
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    if let code = inviteCode {
                        Text("邀请码已生成")
                            .font(TPDesign.editorialSerif(22))
                            .foregroundStyle(TPDesign.obsidian)

                        HStack(spacing: 8) {
                            ForEach(Array(code.enumerated()), id: \.offset) { _, char in
                                Text(String(char))
                                    .font(.system(size: 36, weight: .black, design: .monospaced))
                                    .foregroundStyle(TPDesign.obsidian)
                                    .frame(width: 52, height: 66)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(TPDesign.secondaryBackground)
                                            .shadowSmall()
                                    )
                            }
                        }

                        ShareLink(item: "加入我的旅行「\(travel.name)」！邀请码：\(code)") {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享邀请码")
                                    .font(TPDesign.bodyFont(16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(TPDesign.accentGradient))
                            .shadowLarge()
                        }
                    } else if isGenerating {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在生成邀请码...")
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textTertiary)
                    }

                    Spacer()
                }
                .padding(32)
                .padding(.top, 40)
            }
            .navigationTitle("邀请旅伴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .task {
            isGenerating = true
            do {
                let invite = try await CollaborationService.shared.createInvite(tripId: travel.id, tripName: travel.name)
                inviteCode = invite.inviteCode
                TPHaptic.notification(.success)
            } catch {
                print("[QuickInvite] Failed: \(error)")
            }
            isGenerating = false
        }
    }
}
