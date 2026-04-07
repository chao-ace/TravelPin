import SwiftUI

struct IntelligenceBanner: View {
    @ObservedObject var intelligence = IntelligenceService.shared
    let travel: Travel

    var body: some View {
        if let recommendation = intelligence.activeRecommendation {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    // Concierge Avatar
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 42, height: 42)
                            .shadowGlow(color: Color.tpAccent, radius: 8)

                        Image(systemName: conciergeIcon(for: recommendation.trigger))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("私享家")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                                .tracking(1)

                            Text(conciergeTag(for: recommendation.trigger))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.white.opacity(0.2)))
                        }

                        Text(personalizedMessage(for: recommendation))
                            .font(TPDesign.bodyFont(15))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                    }

                    Spacer()

                    Button {
                        withAnimation { intelligence.dismiss() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(18)

                Divider().opacity(0.3)

                // Action Buttons
                HStack(spacing: 10) {
                    Button {
                        TPHaptic.mechanicalPress()
                        if recommendation.actionType == .swapLocal {
                            if let targetID = recommendation.internalSpotID {
                                intelligence.applySwap(in: travel, targetSpotID: targetID)
                            }
                        } else {
                            intelligence.discoverSomethingNew()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text(actionLabel(for: recommendation.actionType))
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .foregroundStyle(Color.tpAccent)
                        .clipShape(Capsule())
                    }

                    Button {
                        withAnimation { intelligence.dismiss() }
                    } label: {
                        Text("稍后再说")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
            }
            .background(
                ZStack {
                    TPDesign.brandGradient
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.08))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .padding(.horizontal)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .shadow(color: Color.tpAccent.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Personality Helpers

    private func conciergeIcon(for trigger: IntelligenceTrigger) -> String {
        switch trigger {
        case .weather: return "cloud.sun.rain.fill"
        case .fatigue: return "heart.circle.fill"
        case .distance: return "figure.walk"
        }
    }

    private func conciergeTag(for trigger: IntelligenceTrigger) -> String {
        switch trigger {
        case .weather: return "天气"
        case .fatigue: return "体力"
        case .distance: return "附近"
        }
    }

    private func personalizedMessage(for rec: IntelligenceRecommendation) -> String {
        switch rec.trigger {
        case .weather(let condition, let spotName):
            return "发现 \(spotName) \(condition)，建议调整行程。\(rec.subtitle)"
        case .fatigue(let steps):
            if steps > 20000 {
                return "今天已经走了 \(steps) 步，辛苦了！建议换个轻松的活动，让旅途更舒适。"
            }
            return "走了 \(steps) 步，状态不错！不过前方有个隐藏好去处，要不要顺路看看？"
        case .distance(let meters):
            let minutes = Int(meters / 80) // rough walk speed
            return "私享家发现：步行 \(minutes) 分钟有个好评如潮的去处，可以加入今天的行程哦"
        }
    }

    private func actionLabel(for actionType: IntelligenceRecommendation.ActionType) -> String {
        switch actionType {
        case .swapLocal: return "调整行程"
        case .discoverRemote: return "去看看"
        }
    }
}
