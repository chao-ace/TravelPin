import SwiftUI
import SwiftData

// MARK: - Memory Capsule View

struct MemoryCapsuleView: View {
    let memory: MemoryItem
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            TPDesign.cinematicGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 60)

                    // Photo collage
                    if !memory.photoData.isEmpty {
                        photoCollage
                            .padding(.top, 32)
                            .padding(.horizontal, 20)
                    }

                    // AI Reflection card
                    reflectionCard
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // Stats
                    statsRow
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // Spot notes
                    if !memory.spotNotes.isEmpty {
                        spotNotesSection
                            .padding(.top, 28)
                            .padding(.horizontal, 20)
                    }

                    // Actions
                    actionButtons
                        .padding(.top, 36)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 60)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(20)
            }
        }
        .onAppear {
            withAnimation(TPDesign.cinemaReveal) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Capsule icon
            ZStack {
                Circle()
                    .fill(TPDesign.warmGold.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(TPDesign.warmGold)
            }

            Text(locKey: "memory.capsule.title")
                .font(TPDesign.editorialSerif(28))
                .foregroundStyle(.white)

            Text(memory.travelName)
                .font(TPDesign.bodyFont(18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            // Days badge
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 11, weight: .bold))
                Text(String(format: "memory.capsule.days_ago".localized, memory.daysSinceTrip))
            }
            .font(TPDesign.captionFont())
            .foregroundStyle(TPDesign.warmGold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TPDesign.warmGold.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    // MARK: - Photo Collage

    private var photoCollage: some View {
        VStack(spacing: 4) {
            let photos = memory.photoData
            let cols = min(photos.count, 3)

            HStack(spacing: 4) {
                ForEach(0..<min(cols, photos.count), id: \.self) { index in
                    if let uiImage = UIImage(data: photos[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            if photos.count > 3 {
                HStack(spacing: 4) {
                    ForEach(3..<min(5, photos.count), id: \.self) { index in
                        if let uiImage = UIImage(data: photos[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reflection Card

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                Text(locKey: "memory.capsule.reflection")
                    .font(TPDesign.overline())
                    .tracking(1)
            }
            .foregroundStyle(TPDesign.warmGold)

            Text(memory.aiReflection)
                .font(TPDesign.bodyFont(16, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(memory.totalSpots)", label: "memory.stat.spots".localized)
            Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 40)
            statItem(value: "\(memory.daysSinceTrip)", label: "memory.stat.days".localized)
            Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 40)
            statItem(value: "\(memory.totalPhotos)", label: "memory.stat.photos".localized)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                .fill(.white.opacity(0.04))
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TPDesign.titleFont(22, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(TPDesign.captionFont())
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Spot Notes

    private var spotNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 12, weight: .bold))
                Text(locKey: "memory.capsule.notes")
                    .font(TPDesign.overline())
                    .tracking(1)
            }
            .foregroundStyle(TPDesign.warmGold)

            ForEach(memory.spotNotes.prefix(3), id: \.self) { note in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(TPDesign.warmGold.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .padding(.top, 8)
                    Text(note)
                        .font(TPDesign.bodyFont(14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text(locKey: "memory.capsule.share")
                }
                .font(TPDesign.bodyFont(15, weight: .bold))
                .foregroundStyle(TPDesign.deepNavy)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: TPDesign.radiusMedium)
                        .fill(TPDesign.warmGold)
                )
            }

            Button {
                dismiss()
            } label: {
                Text(locKey: "memory.capsule.close")
                    .font(TPDesign.bodyFont(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Memory Capsule Banner (for Dashboard)

struct MemoryCapsuleBanner: View {
    let travel: Travel
    let daysAgo: Int
    @State private var pulseAnimation = false

    var body: some View {
        Button {
            Task {
                if let memory = await MemoryService.shared.generateMemory(for: travel) {
                    // Navigate to memory view - handled by parent
                }
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TPDesign.warmGold.opacity(pulseAnimation ? 0.3 : 0.15))
                        .frame(width: 52, height: 52)
                        .blur(radius: 8)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(TPDesign.warmGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "memory.banner.title".localized, travel.name))
                        .font(TPDesign.bodyFont(15, weight: .bold))
                        .foregroundStyle(TPDesign.textPrimary)
                        .lineLimit(1)

                    Text(String(format: "memory.banner.subtitle".localized, daysAgo))
                        .font(TPDesign.captionFont())
                        .foregroundStyle(TPDesign.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                    .fill(TPDesign.warmGold.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: TPDesign.radiusLarge)
                            .stroke(TPDesign.warmGold.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadowSmall()
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}
