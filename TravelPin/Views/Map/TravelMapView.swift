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

                // Download Button
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
        }
        .safeAreaInset(edge: .bottom) {
            daySelector
        }
        .onAppear {
            if !NetworkMonitor.shared.isConnected {
                ToastManager.shared.show(type: .warning, message: "map.error.offline".localized)
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
    }

    private func downloadAction() {
        guard !isDownloading else { return }
        TPHaptic.selection()
        isDownloading = true
        downloadProgress = 0

        // Calculate region from all spots in this travel
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

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                // "All" button
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
        .glassCard(cornerRadius: 0)
    }

    // MARK: - Route Optimization

    private func optimizeRoute() {
        isOptimizing = true
        Task {
            let optimized = await LocationService.shared.optimizeRouteWithDistances(spots: travel.spots)
            await MainActor.run {
                for (index, spot) in optimized.enumerated() {
                    spot.sequence = index + 1
                }
                isOptimizing = false
                TPHaptic.notification(.success)
                ToastManager.shared.show(type: .success, message: "map.toast.route_optimized".localized)
            }
        }
    }
}
