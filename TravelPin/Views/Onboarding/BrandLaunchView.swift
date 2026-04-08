import SwiftUI
import SwiftData

// MARK: - Onboarding Container (Splash → Wizard)

struct BrandLaunchView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    @State private var splashPhase: CGFloat = 0
    @State private var appear = false
    @State private var showTagline = false

    var body: some View {
        Group {
            if showSplash {
                splashScreen
            } else if !hasCompletedOnboarding {
                OnboardingWizardView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .onAppear {
            withAnimation(.expoOut(duration: 1.5)) {
                appear = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                splashPhase = 360
            }
            withAnimation(.easeOut(duration: 1.0).delay(1.2)) {
                showTagline = true
            }

            if hasCompletedOnboarding {
                // Returning user: short splash only
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            } else {
                // New user: splash → onboarding wizard
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
        }
    }

    // MARK: - Splash Screen (unchanged visual)

    private var splashScreen: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.05).ignoresSafeArea()

            Circle()
                .fill(TPDesign.celestialBlue.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: -50)
                .scaleEffect(appear ? 1.2 : 0.8)

            VStack(spacing: 60) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(TPDesign.celestialBlue.opacity(0.1), lineWidth: 40)
                        .blur(radius: 20)
                        .scaleEffect(appear ? 1.1 : 0.9)

                    EndlessRibbonShape()
                        .trim(from: 0, to: appear ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [TPDesign.celestialBlue, TPDesign.marineDeep.opacity(0.8), TPDesign.celestialBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(splashPhase))

                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(.white)
                        .shadow(color: TPDesign.celestialBlue, radius: 10)
                        .opacity(appear ? 1 : 0)
                        .scaleEffect(appear ? 1 : 0.5)
                }

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("TravelPin")
                            .font(.system(size: 42, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                            .tracking(10)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, .white.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 200, height: 0.5)
                            .opacity(appear ? 1 : 0)
                            .scaleEffect(x: appear ? 1 : 0)
                    }

                    VStack(spacing: 12) {
                        Text(locKey: "splash.tagline")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(4)

                        Text("THE ENDLESS JOURNEY RIBBON")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(TPDesign.celestialBlue)
                            .tracking(2)
                    }
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 10)
                }

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Onboarding Wizard (First-Trip Experience)

struct OnboardingWizardView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var travelName = ""
    @State private var selectedType: TravelType = .tourism
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @Environment(\.modelContext) private var modelContext

    private let pages = 4

    var body: some View {
        ZStack {
            TPDesign.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Indicator
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                // Page Content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    namePage.tag(1)
                    datePage.tag(2)
                    readyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)

                // Bottom Actions
                bottomActions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? TPDesign.celestialBlue : TPDesign.divider)
                    .frame(height: 3)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(TPDesign.celestialBlue.opacity(0.08))
                    .frame(width: 240, height: 240)

                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(TPDesign.celestialBlue)
            }

            VStack(spacing: 16) {
                Text(locKey: "onboarding.welcome.title")
                    .font(TPDesign.editorialSerif(32))
                    .foregroundStyle(TPDesign.obsidian)

                Text(locKey: "onboarding.welcome.subtitle")
                    .font(TPDesign.bodyFont(17))
                    .foregroundStyle(TPDesign.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 32)

            // Feature Highlights
            VStack(spacing: 20) {
                featureRow(icon: "map.fill", title: "onboarding.feature.map.title".localized, desc: "onboarding.feature.map.desc".localized)
                featureRow(icon: "wand.and.stars", title: "onboarding.feature.ai.title".localized, desc: "onboarding.feature.ai.desc".localized)
                featureRow(icon: "doc.richtext", title: "onboarding.feature.poster.title".localized, desc: "onboarding.feature.poster.desc".localized)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.tpAccent)
                .frame(width: 40, height: 40)
                .background(Color.tpAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TPDesign.bodyFont(16, weight: .bold))
                    .foregroundStyle(TPDesign.obsidian)
                Text(desc)
                    .font(TPDesign.bodyFont(13))
                    .foregroundStyle(TPDesign.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Page 1: Name Your Trip

    private var namePage: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(TPDesign.warmAmber)

            VStack(spacing: 12) {
                Text(locKey: "onboarding.name.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "onboarding.name.subtitle")
                    .font(TPDesign.bodyFont(15))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                TextField("onboarding.name.placeholder".localized, text: $travelName)
                    .font(TPDesign.bodyFont(18))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tpAccent.opacity(travelName.isEmpty ? 0.2 : 0.5), lineWidth: 1))
                    )
                    .shadowSmall()

                Text(locKey: "onboarding.name.typeLabel")
                    .font(TPDesign.overline())
                    .foregroundStyle(TPDesign.textTertiary)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(TravelType.allCases, id: \.self) { type in
                        let isSelected = selectedType == type
                        Button {
                            TPHaptic.selection()
                            selectedType = type
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                Text(type.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? .white : TPDesign.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                if isSelected {
                                    TPDesign.accentGradient
                                } else {
                                    Color.white
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.clear : TPDesign.divider, lineWidth: 1))
                        }
                        .buttonStyle(CinematicButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 2: Date Selection

    private var datePage: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(TPDesign.celestialBlue)

            VStack(spacing: 12) {
                Text(locKey: "onboarding.date.title")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                Text(locKey: "onboarding.date.subtitle")
                    .font(TPDesign.bodyFont(15))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            VStack(spacing: 20) {
                DatePicker("onboarding.date.start".localized, selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadowSmall()
                    )

                DatePicker("onboarding.date.end".localized, selection: $endDate, in: startDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadowSmall()
                    )
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 3: Ready

    private var readyPage: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.tpAccent.opacity(0.1))
                    .frame(width: 200, height: 200)

                Image(systemName: "sparkles")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(Color.tpAccent)
            }

            VStack(spacing: 12) {
                Text(travelName.isEmpty ? "onboarding.ready.title".localized : "\(travelName)")
                    .font(TPDesign.editorialSerif(28))
                    .foregroundStyle(TPDesign.obsidian)
                    .multilineTextAlignment(.center)

                Text(locKey: "onboarding.ready.subtitle")
                    .font(TPDesign.bodyFont(15))
                    .foregroundStyle(TPDesign.textSecondary)
            }

            // Summary Card
            VStack(spacing: 16) {
                summaryRow(icon: "mappin.and.ellipse", label: "onboarding.ready.destination".localized, value: travelName.isEmpty ? "onboarding.ready.unnamed".localized : travelName)
                Divider().padding(.leading, 44)
                summaryRow(icon: "tag.fill", label: "onboarding.ready.type".localized, value: selectedType.displayName)
                Divider().padding(.leading, 44)
                summaryRow(icon: "calendar", label: "onboarding.ready.date".localized, value: "\(startDate.formatted(.dateTime.month(.abbreviated).day())) - \(endDate.formatted(.dateTime.month(.abbreviated).day()))")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadowMedium()
            )
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.tpAccent)
                .frame(width: 28, height: 28)
                .background(Color.tpAccent.opacity(0.1))
                .clipShape(Circle())
            Text(label)
                .font(TPDesign.bodyFont(14))
                .foregroundStyle(TPDesign.textSecondary)
            Spacer()
            Text(value)
                .font(TPDesign.bodyFont(14, weight: .bold))
                .foregroundStyle(TPDesign.obsidian)
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    TPHaptic.selection()
                    withAnimation { currentPage -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(locKey: "onboarding.action.back")
                    }
                    .font(TPDesign.bodyFont(15))
                    .foregroundStyle(TPDesign.textSecondary)
                }
            }

            Spacer()

            Button {
                TPHaptic.notification(.success)
                if currentPage < pages - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    createFirstTravel()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(locKey: currentPage == pages - 1 ? "onboarding.action.start" : "onboarding.action.next")
                    if currentPage < pages - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(TPDesign.accentGradient)
                .clipShape(Capsule())
                .shadowLarge()
            }
            .buttonStyle(CinematicButtonStyle())
        }
    }

    // MARK: - Create First Travel

    private func createFirstTravel() {
        let name = travelName.isEmpty ? "onboarding.default.name".localized : travelName
        let travel = Travel(name: name, startDate: startDate, endDate: endDate, status: TravelStatus.planning.rawValue, type: selectedType.rawValue)
        modelContext.insert(travel)
        
        // Finalize buffered operations to ensure data appears immediately in @Query
        try? modelContext.processPendingChanges()
        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Endless Ribbon Geometry

struct EndlessRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let center = CGPoint(x: w/2, y: h/2)

        for i in 0...360 {
            let angle = CGFloat(i) * .pi / 180
            let r = (w/2) * (0.8 + 0.2 * sin(angle * 3))
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Premium Animation Extension

extension Animation {
    static func expoOut(duration: Double = 1.0) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}

#Preview {
    BrandLaunchView()
}
