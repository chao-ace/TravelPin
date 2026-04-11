import SwiftUI
import MapKit

// MARK: - Route Replay View

struct RouteReplayView: View {
    let waypoints: [RouteWaypoint]
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var replayIndex: Int = 0
    @State private var isReplaying = false
    @State private var replaySpeed: Double = 50 // waypoints per second

    init(waypoints: [RouteWaypoint]) {
        self.waypoints = waypoints
        if let first = waypoints.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    var body: some View {
        ZStack {
            Map(initialPosition: .region(region)) {
                // Route polyline
                MapPolyline(coordinates: waypoints.map { $0.coordinate })
                    .stroke(TPDesign.celestialBlue.opacity(0.6), lineWidth: 4)

                // Current replay position
                if !waypoints.isEmpty && replayIndex < waypoints.count {
                    Annotation("", coordinate: waypoints[replayIndex].coordinate) {
                        ZStack {
                            Circle()
                                .fill(TPDesign.celestialBlue)
                                .frame(width: 16, height: 16)
                                .shadow(color: TPDesign.celestialBlue.opacity(0.4), radius: 6)
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                // Start marker
                if let first = waypoints.first {
                    Annotation("出发", coordinate: first.coordinate) {
                        ZStack {
                            Circle().fill(Color.green).frame(width: 24, height: 24)
                            Image(systemName: "flag.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                // End marker
                if let last = waypoints.last, waypoints.count > 1 {
                    Annotation("终点", coordinate: last.coordinate) {
                        ZStack {
                            Circle().fill(TPDesign.warmGold).frame(width: 24, height: 24)
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            // Controls overlay
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Progress bar
                    if !waypoints.isEmpty {
                        ProgressView(value: Double(replayIndex), total: Double(waypoints.count - 1))
                            .tint(TPDesign.celestialBlue)
                            .padding(.horizontal, 20)
                    }

                    // Info
                    HStack(spacing: 20) {
                        Label("\(waypoints.count) 个记录点", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        Label(formatDistance(), systemImage: "figure.walk")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                    // Playback controls
                    HStack(spacing: 24) {
                        Button { resetReplay() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        Button { toggleReplay() } label: {
                            ZStack {
                                Circle()
                                    .fill(TPDesign.celestialBlue)
                                    .frame(width: 56, height: 56)
                                Image(systemName: isReplaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }

                        // Speed control
                        Menu {
                            Button("1x") { replaySpeed = 30 }
                            Button("2x") { replaySpeed = 60 }
                            Button("4x") { replaySpeed = 120 }
                        } label: {
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.1), lineWidth: 0.5))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("route.replay.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Replay Logic

    private func toggleReplay() {
        if isReplaying {
            isReplaying = false
        } else {
            isReplaying = true
            advanceReplay()
        }
    }

    private func advanceReplay() {
        guard isReplaying, replayIndex < waypoints.count - 1 else {
            isReplaying = false
            return
        }

        replayIndex += 1

        // Animate map to follow
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: waypoints[replayIndex].coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        let delay = 1.0 / replaySpeed
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            advanceReplay()
        }
    }

    private func resetReplay() {
        isReplaying = false
        replayIndex = 0
        if let first = waypoints.first {
            withAnimation {
                region = MKCoordinateRegion(
                    center: first.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    private func formatDistance() -> String {
        let total = RouteTrackingService.shared.totalDistance
        if total >= 1000 {
            return String(format: "%.1f km", total / 1000)
        }
        return "\(Int(total)) m"
    }
}
