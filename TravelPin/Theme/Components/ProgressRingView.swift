import SwiftUI

struct ProgressRingView: View {
    var progress: Double // 0.0 ~ 1.0
    var lineWidth: CGFloat = 6
    var size: CGFloat = 48
    var ringColor: Color = .tpAccent
    var showLabel: Bool = true
    var labelStyle: LabelStyle = .percentage

    enum LabelStyle {
        case percentage
        case fraction(filled: Int, total: Int)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.12), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    TPDesign.accentGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(TPDesign.springGentle, value: progress)

            // Center label
            if showLabel {
                Group {
                    switch labelStyle {
                    case .percentage:
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    case .fraction(let filled, let total):
                        VStack(spacing: 1) {
                            Text("\(filled)")
                                .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                            Text("/\(total)")
                                .font(.system(size: size * 0.16, weight: .medium))
                                .foregroundStyle(TPDesign.textTertiary)
                        }
                    }
                }
                .foregroundStyle(TPDesign.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Inline Mini Progress Ring

struct MiniProgressRing: View {
    var progress: Double
    var size: CGFloat = 24
    var color: Color = .tpAccent

    var body: some View {
        Circle()
            .stroke(color.opacity(0.15), lineWidth: 3)
            .overlay(
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            )
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.4), value: progress)
    }
}
