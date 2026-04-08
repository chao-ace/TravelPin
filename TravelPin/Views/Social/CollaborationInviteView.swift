import SwiftUI
import SwiftData

// MARK: - CollaborationInviteView

struct CollaborationInviteView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var collab = CollaborationService.shared
    @State private var inviteCode = ""
    @State private var isGenerating = false
    @State private var generatedCode: String?
    @State private var generatedTripName: String?
    @State private var selectedTripForInvite: Travel?
    @State private var showTripPicker = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    @Query(filter: #Predicate<Travel> { $0.isDeleted == false },
           sort: \Travel.startDate) private var travels: [Travel]

    var body: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        joinByCodeSection
                        createInviteSection

                        if !collab.pendingInvites.isEmpty {
                            pendingInvitesSection
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("同行协作")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTripPicker) {
                tripPickerSheet
            }
            .alert("加入成功！", isPresented: $showSuccess) {
                Button("好的") {}
            } message: {
                Text("旅程已添加到你的计划中")
            }
            .alert("出错了", isPresented: .constant(errorMessage != nil), actions: {
                Button("好的") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
        .task {
            await collab.fetchPendingInvites()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(TPDesign.warmGold.opacity(0.08))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(TPDesign.warmGold)
            }

            Text("与旅伴一起规划行程")
                .font(TPDesign.editorialSerif(24))
                .foregroundStyle(TPDesign.obsidian)

            Text("邀请朋友共同编辑行程，实时同步每个人的足迹和想法")
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Join by Code

    private var joinByCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("加入协作")
                .font(TPDesign.editorialSerif(20))
                .foregroundStyle(TPDesign.obsidian)

            HStack(spacing: 12) {
                TextField("输入6位邀请码", text: $inviteCode)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(TPDesign.divider, lineWidth: 0.5))
                    )

                Button {
                    joinByCode()
                } label: {
                    ZStack {
                        Circle()
                            .fill(inviteCode.count == 6 ? TPDesign.accentGradient : LinearGradient(colors: [TPDesign.obsidian.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 48, height: 48)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(inviteCode.count != 6)
            }
        }
    }

    // MARK: - Create Invite

    private var createInviteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("邀请旅伴")
                .font(TPDesign.editorialSerif(20))
                .foregroundStyle(TPDesign.obsidian)

            if let code = generatedCode, let tripName = generatedTripName {
                // Code generated state
                generatedCodeSection(code: code, tripName: tripName)
            } else {
                // Prompt to select trip
                Button {
                    showTripPicker = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.tpAccent.opacity(0.08))
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.tpAccent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("选择一个旅程")
                                .font(TPDesign.bodyFont(16, weight: .semibold))
                                .foregroundStyle(TPDesign.obsidian)
                            Text("为选中的旅程生成邀请码")
                                .font(TPDesign.bodyFont(13))
                                .foregroundStyle(TPDesign.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(TPDesign.divider, lineWidth: 0.5))
                    )
                }
                .buttonStyle(CinematicButtonStyle())
            }
        }
    }

    private func generatedCodeSection(code: String, tripName: String) -> some View {
        VStack(spacing: 20) {
            // Trip info
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.tpAccent)
                Text(tripName)
                    .font(TPDesign.bodyFont(15, weight: .semibold))
                    .foregroundStyle(TPDesign.obsidian)
                Spacer()
            }

            // Code display
            HStack(spacing: 8) {
                ForEach(Array(code.enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(TPDesign.obsidian)
                        .frame(width: 48, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadowSmall()
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Share button
            ShareLink(item: "加入我的旅行「\(tripName)」！邀请码：\(code)") {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享邀请码")
                        .font(TPDesign.bodyFont(16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(TPDesign.accentGradient))
                .shadowLarge()
            }
            .buttonStyle(CinematicButtonStyle())

            // Reset
            Button("选择其他旅程") {
                generatedCode = nil
                generatedTripName = nil
            }
            .font(TPDesign.bodyFont(13))
            .foregroundStyle(TPDesign.textTertiary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(TPDesign.divider, lineWidth: 0.5))
        )
        .shadowSmall()
    }

    // MARK: - Pending Invites

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("待处理邀请")
                .font(TPDesign.editorialSerif(20))
                .foregroundStyle(TPDesign.obsidian)

            ForEach(collab.pendingInvites) { invite in
                inviteRow(invite)
            }
        }
    }

    private func inviteRow(_ invite: CollaborationInvite) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TPDesign.warmGold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(TPDesign.warmGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(invite.tripName)
                    .font(TPDesign.bodyFont(15, weight: .semibold))
                    .foregroundStyle(TPDesign.obsidian)
                Text("来自 \(invite.inviterName) · \(invite.role.displayName)")
                    .font(TPDesign.bodyFont(12))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    acceptInvite(invite)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.tpAccent)
                }

                Button {
                    rejectInvite(invite)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(TPDesign.textTertiary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(TPDesign.divider, lineWidth: 0.5))
        )
    }

    // MARK: - Trip Picker Sheet

    private var tripPickerSheet: some View {
        NavigationStack {
            ZStack {
                TPDesign.background.ignoresSafeArea()

                if travels.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(TPDesign.textTertiary)
                        Text("还没有旅程")
                            .font(TPDesign.bodyFont(15))
                            .foregroundStyle(TPDesign.textTertiary)
                    }
                } else {
                    List(travels) { travel in
                        Button {
                            createInviteFor(travel)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.tpAccent.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: travel.type.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.tpAccent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(travel.name)
                                        .font(TPDesign.bodyFont(15, weight: .semibold))
                                        .foregroundStyle(TPDesign.obsidian)
                                    Text(travel.dateRangeString)
                                        .font(.system(size: 12))
                                        .foregroundStyle(TPDesign.textSecondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("选择旅程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { showTripPicker = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func joinByCode() {
        guard inviteCode.count == 6 else { return }
        TPHaptic.selection()

        Task {
            do {
                if let _ = try await collab.acceptInvite(code: inviteCode, modelContext: modelContext) {
                    inviteCode = ""
                    showSuccess = true
                }
            } catch let error as CollaborationError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func createInviteFor(_ travel: Travel) {
        showTripPicker = false
        TPHaptic.selection()

        Task {
            do {
                let invite = try await collab.createInvite(tripId: travel.id, tripName: travel.name)
                generatedCode = invite.inviteCode
                generatedTripName = travel.name
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func acceptInvite(_ invite: CollaborationInvite) {
        TPHaptic.notification(.success)
        Task {
            do {
                if let _ = try await collab.acceptInvite(code: invite.inviteCode, modelContext: modelContext) {
                    await collab.fetchPendingInvites()
                    showSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func rejectInvite(_ invite: CollaborationInvite) {
        TPHaptic.selection()
        Task {
            do {
                try await collab.rejectInvite(code: invite.inviteCode)
                await collab.fetchPendingInvites()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
