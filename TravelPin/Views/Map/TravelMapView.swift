import SwiftUI
import MapKit
import SwiftData

struct TravelMapView: View {
    @Bindable var travel: Travel
    @State private var isOfflineMode = false
    @State private var selectedDay: Int = 1
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var showDownloadSuccess = false
    @State private var downloadedTiles = 0
    @State private var showClearConfirm = false
    @State private var transportType: MKDirectionsTransportType = .automobile
    @State private var showOptimizeConfirm = false
    @State private var isOptimizing = false

    // Route comparison
    @State private var showRouteComparison = false
    @State private var originalOrder: [Spot] = []
    @State private var optimizedOrder: [Spot] = []

    // First-use gesture hint
    @AppStorage("map.gestureHintShown") private var gestureHintShown = false
    @State private var showGestureHint = false

    // Download estimation
    @State private var estimatedTiles = 0
    @State private var estimatedSize: String = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            InteractiveOfflineMap(travel: travel, isOfflineMode: $isOfflineMode)
                .ignoresSafeArea()

            // Map Controls
            VStack(spacing: 12) {
                // Transport Type Toggle
                HStack(spacing: 0) {
                    Button {
                        TPHaptic.selection()
                        transportType = .automobile
                    } label: {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14, weight: transportType == .automobile ? .bold : .regular))
                            .foregroundStyle(transportType == .automobile ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(transportType == .automobile ? Color.tpAccent : .clear)
                            .clipShape(Capsule())
                    }

                    Button {
                        TPHaptic.selection()
                        transportType = .walking
                    } label: {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 14, weight: transportType == .walking ? .bold : .regular))
                            .foregroundStyle(transportType == .walking ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(transportType == .walking ? Color.tpAccent : .clear)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(TPDesign.secondaryBackground.opacity(0.6).background(.ultraThinMaterial))
                .clipShape(Capsule())

                // Offline Mode Toggle
                Button(action: {
                    TPHaptic.selection()
                    isOfflineMode.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isOfflineMode ? "airplane.circle.fill" : "network")
                            .font(.system(size: 16, weight: .semibold))
                        if isOfflineMode {
                            Text(locKey: "map.status.offline")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundStyle(isOfflineMode ? .white : .primary)
                    .padding(.horizontal, isOfflineMode ? 14 : 12)
                    .padding(.vertical, 10)
                    .background {
                        if isOfflineMode {
                            Color.tpAccent
                        } else {
                            TPDesign.secondaryBackground.opacity(0.6).background(.ultraThinMaterial)
                        }
                    }
                    .clipShape(Capsule())
                }

                // Download Button (with estimation)
                Button(action: downloadAction) {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView()
                                .tint(.primary)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        if isDownloading {
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, isDownloading ? 14 : 12)
                    .padding(.vertical, 10)
                    .background(TPDesign.secondaryBackground.opacity(0.6).background(.ultraThinMaterial))
                    .clipShape(Capsule())
                }
                .disabled(isDownloading)

                // Route Optimization Button
                if travel.spots.filter({ $0.hasLocation }).count >= 3 {
                    Button {
                        showOptimizeConfirm = true
                    } label: {
                        if isOptimizing {
                            ProgressView()
                                .tint(.primary)
                                .frame(width: 20, height: 20)
                                .padding(10)
                        } else {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(TPDesign.celestialBlue)
                                .padding(10)
                        }
                    }
                    .background(TPDesign.secondaryBackground.opacity(0.6).background(.ultraThinMaterial))
                    .clipShape(Capsule())
                }

                // Clear Cache Button (only in offline mode)
                if isOfflineMode {
                    Button(action: { showClearConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(10)
                            .background(TPDesign.secondaryBackground.opacity(0.6).background(.ultraThinMaterial))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()

            // First-use gesture hint overlay
            if showGestureHint {
                gestureHintOverlay
            }
        }
        .safeAreaInset(edge: .bottom) {
            daySelector
        }
        .onAppear {
            calculateDownloadEstimate()
            if !NetworkMonitor.shared.isConnected {
                ToastManager.shared.show(type: .warning, message: "map.error.offline".localized)
            }
            // Show gesture hint on first use
            if !gestureHintShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(TPDesign.springDefault) {
                        showGestureHint = true
                    }
                }
            }
        }
        .navigationTitle("detail.menu.explore_map".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("map.alert.download_success.title".localized, isPresented: $showDownloadSuccess) {
            Button("common.done".localized) { }
        } message: {
            Text(String(format: "map.alert.download_success.message".localized, downloadedTiles, MapTileManager.shared.cacheSizeDescription))
        }
        .confirmationDialog("map.alert.clear_cache.title".localized, isPresented: $showClearConfirm) {
            Button("map.action.clear".localized, role: .destructive) {
                MapTileManager.shared.clearCache()
                TPHaptic.notification(.success)
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text(String(format: "map.alert.clear_cache.message".localized, MapTileManager.shared.cacheSizeDescription))
        }
        .confirmationDialog("map.alert.optimize_route.title".localized, isPresented: $showOptimizeConfirm) {
            Button("map.action.optimize".localized) {
                optimizeRoute()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text(String(format: "map.alert.optimize_route.message".localized, travel.spots.filter { $0.hasLocation }.count))
        }
        .sheet(isPresented: $showRouteComparison) {
            RouteComparisonView(original: originalOrder, optimized: optimizedOrder, onApply: {
                applyOptimizedOrder()
                showRouteComparison = false
            })
        }
    }

    // MARK: - Gesture Hint Overlay

    private var gestureHintOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                // Pinch hint
                HStack(spacing: 12) {
                    Image(systemName: "hand.pinch")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.tpAccent)
                    Text(locKey: "map.hint.pinch")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.white)
                }

                // Drag hint
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.tpAccent)
                    Text(locKey: "map.hint.drag")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.white)
                }

                // Marker tap hint
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.tpAccent)
                    Text(locKey: "map.hint.tap_marker")
                        .font(TPDesign.bodyFont(14))
                        .foregroundStyle(.white)
                }

                Button {
                    withAnimation(TPDesign.springDefault) {
                        showGestureHint = false
                    }
                    gestureHintShown = true
                    TPHaptic.selection()
                } label: {
                    Text(locKey: "map.hint.got_it")
                        .font(TPDesign.bodyFont(14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.tpAccent)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadowMedium()
            )
            .padding(.horizontal, 32)

            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Download Estimation

    private func calculateDownloadEstimate() {
        let coordinates = travel.spots.compactMap { $0.coordinate }
        guard !coordinates.isEmpty else {
            estimatedTiles = 0
            estimatedSize = "0 MB"
            return
        }

        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.3, 0.05),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.3, 0.05)
        )

        // Rough estimate: ~200 tiles per 0.1° span at zoom levels 12-15
        let areaFactor = span.latitudeDelta * span.longitudeDelta
        estimatedTiles = max(Int(areaFactor * 20000), 50)
        let sizeMB = Double(estimatedTiles) * 0.015 // ~15KB per tile average
        if sizeMB < 1 {
            estimatedSize = String(format: "%.0f KB", sizeMB * 1024)
        } else {
            estimatedSize = String(format: "%.1f MB", sizeMB)
        }
    }

    // MARK: - Download Action

    private func downloadAction() {
        guard !isDownloading else { return }
        TPHaptic.selection()
        isDownloading = true
        downloadProgress = 0

        let coordinates = travel.spots.compactMap { $0.coordinate }
        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan

        if coordinates.isEmpty {
            center = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
            span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        } else if coordinates.count == 1 {
            center = coordinates[0]
            span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        } else {
            let lats = coordinates.map(\.latitude)
            let lons = coordinates.map(\.longitude)
            let minLat = lats.min()!, maxLat = lats.max()!
            let minLon = lons.min()!, maxLon = lons.max()!
            center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
            span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.3, 0.05), longitudeDelta: max((maxLon - minLon) * 1.3, 0.05))
        }

        let region = MKCoordinateRegion(center: center, span: span)

        Task {
            let tiles = await MapTileManager.shared.downloadRegion(region, zoomRange: 12...15)
            await MainActor.run {
                isDownloading = false
                downloadedTiles = tiles
                downloadProgress = 1.0
                TPHaptic.notification(.success)
                showDownloadSuccess = true
            }
        }
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        VStack(spacing: 0) {
            // Download estimate bar
            if !isOfflineMode && estimatedTiles > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text(String(format: "map.download.estimate".localized, estimatedSize))
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(TPDesign.alabaster.opacity(0.5))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        selectedDay = 0
                    } label: {
                        Text(locKey: "map.action.all")
                            .font(.caption).bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedDay == 0 ? Color.tpAccent : Color.tpSurface)
                            .foregroundStyle(selectedDay == 0 ? .white : .primary)
                            .clipShape(Capsule())
                    }

                    ForEach(travel.itineraries.sorted(by: { $0.day < $1.day })) { itinerary in
                        Button {
                            selectedDay = itinerary.day
                        } label: {
                            Text("\("add.itinerary.day".localized) \(itinerary.day)\("add.itinerary.unit".localized)")
                                .font(.caption).bold()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedDay == itinerary.day ? Color.tpAccent : Color.tpSurface)
                                .foregroundStyle(selectedDay == itinerary.day ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
        }
        .glassCard(cornerRadius: 0)
    }

    // MARK: - Route Optimization

    private func optimizeRoute() {
        isOptimizing = true
        originalOrder = travel.spots.filter { $0.hasLocation }

        Task {
            let optimized = await LocationService.shared.optimizeRouteWithDistances(spots: travel.spots)
            await MainActor.run {
                optimizedOrder = optimized
                isOptimizing = false

                if originalOrder.count >= 2 {
                    showRouteComparison = true
                } else {
                    applyOptimizedOrder()
                }
            }
        }
    }

    private func applyOptimizedOrder() {
        for (index, spot) in optimizedOrder.enumerated() {
            spot.sequence = index + 1
        }
        TPHaptic.notification(.success)
        ToastManager.shared.show(type: .success, message: "map.toast.route_optimized".localized)
    }
}

// MARK: - Route Comparison View

private struct RouteComparisonView: View {
    let original: [Spot]
    let optimized: [Spot]
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(locKey: "map.compare.title")
                            .font(TPDesign.editorialSerif(26))
                            .foregroundStyle(TPDesign.obsidian)
                        Text(locKey: "map.compare.subtitle")
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)

                    // Before
                    routeSection(
                        title: Text(locKey: "map.compare.before"),
                        spots: original,
                        color: .secondary
                    )

                    // Arrow
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.tpAccent)
                        Spacer()
                    }

                    // After
                    routeSection(
                        title: Text(locKey: "map.compare.after"),
                        spots: optimized,
                        color: Color.tpAccent
                    )

                    // Apply button
                    CinematicPrimaryButton(
                        locKey: "map.compare.apply",
                        icon: "checkmark.circle"
                    ) {
                        onApply()
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(TPDesign.background)
            .navigationTitle(locKey: "map.compare.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
            }
        }
    }

    private func routeSection(title: Text, spots: [Spot], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title
                .font(TPDesign.overline())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(spots.prefix(8).enumerated()), id: \.element.id) { index, spot in
                    HStack(spacing: 12) {
                        // Number badge
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.name)
                                .font(TPDesign.bodyFont(14, weight: .medium))
                                .foregroundStyle(TPDesign.obsidian)
                                .lineLimit(1)
                            if let address = spot.address {
                                Text(address)
                                    .font(TPDesign.captionFont())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(systemName: spot.type.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if index < min(spots.count, 8) - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(TPDesign.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
        }
    }
}
