import SwiftUI
import MapKit

// MARK: - FootprintHeatmapView

struct FootprintHeatmapView: View {
    let travels: [Travel]

    /// All spots across all travels that have valid coordinates.
    private var allSpots: [Spot] {
        travels.flatMap { $0.spots }.filter { $0.hasLocation }
    }

    /// Unique cities inferred from spot addresses (simple heuristic).
    private var cityCount: Int {
        let cities = Set(
            allSpots.compactMap { spot -> String? in
                guard let address = spot.address else { return nil }
                // Take the first comma-separated segment as the city name.
                return address.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces)
            }
        )
        return cities.count
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen heatmap
            HeatmapMapViewRepresentable(spots: allSpots)
                .ignoresSafeArea()

            // Floating legend card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Label {
                        Text(String(format: "footprint.heatmap.spots_count".localized, allSpots.count))
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textPrimary)
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(TPDesign.celestialBlue)
                    }

                    Label {
                        Text(String(format: "footprint.heatmap.cities".localized, cityCount))
                            .font(TPDesign.bodyFont(14))
                            .foregroundStyle(TPDesign.textPrimary)
                    } icon: {
                        Image(systemName: "building.2.crop.circle.fill")
                            .foregroundStyle(TPDesign.warmAmber)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: TPDesign.radiusMedium)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .cinematicFadeIn(delay: 0.3)
        }
        .navigationTitle("footprint.heatmap.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - HeatmapMapViewRepresentable

struct HeatmapMapViewRepresentable: UIViewControllerRepresentable {
    let spots: [Spot]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MKViewController {
        let vc = MKViewController()
        vc.delegate = context.coordinator
        vc.updateSpots(spots)
        return vc
    }

    func updateUIViewController(_ uiViewController: MKViewController, context: Context) {
        uiViewController.updateSpots(spots)
    }

    class Coordinator: NSObject {
        // Bridge for delegate callbacks if needed in the future.
    }
}

// MARK: - MKViewController

class MKViewController: UIViewController, MKMapViewDelegate {

    var mapView: MKMapView!
    private var currentSpots: [Spot] = []

    weak var delegate: AnyObject?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .excludingAll

        view.addSubview(mapView)
    }

    // MARK: - Public

    func updateSpots(_ spots: [Spot]) {
        currentSpots = spots

        guard let mapView else { return }

        // Remove existing annotations and overlays.
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add annotations for every spot with a valid coordinate.
        let annotations: [MKPointAnnotation] = spots.compactMap { spot in
            guard let coordinate = spot.coordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = spot.name
            return annotation
        }

        mapView.addAnnotations(annotations)

        // Add circle overlays for clusters.
        let clusters = computeClusters(from: spots)
        for cluster in clusters {
            let circle = MKCircle(center: cluster.center, radius: cluster.radius)
            mapView.addOverlay(circle)
        }

        // Auto-zoom to fit all annotations.
        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }

    // MARK: - MKMapViewDelegate — Annotations

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }

        let identifier = "HeatmapPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.markerTintColor = UIColor(TPDesign.celestialBlue)
        annotationView?.glyphImage = UIImage(systemName: "footprint.fill")
        annotationView?.canShowCallout = true
        annotationView?.displayPriority = .required

        return annotationView
    }

    // MARK: - MKMapViewDelegate — Overlays

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = UIColor(TPDesign.celestialBlue.opacity(0.2))
        renderer.strokeColor = UIColor(TPDesign.celestialBlue.opacity(0.35))
        renderer.lineWidth = 1.0
        return renderer
    }

    // MARK: - Clustering

    /// A simple density-based cluster of spots.
    private struct SpotCluster {
        let center: CLLocationCoordinate2D
        let radius: Double // meters
        let count: Int
    }

    /// Groups nearby spots into clusters using a grid-based approach.
    /// Grid cell size is approximately 5 km. Radius scales with spot count.
    private func computeClusters(from spots: [Spot]) -> [SpotCluster] {
        let locatedSpots = spots.compactMap { spot -> (spot: Spot, coord: CLLocationCoordinate2D)? in
            guard let coord = spot.coordinate else { return nil }
            return (spot, coord)
        }

        guard !locatedSpots.isEmpty else { return [] }

        // Grid-based clustering: round lat/lon to ~5 km precision (~0.045 degrees).
        let gridSize = 0.045
        var buckets: [String: [(spot: Spot, coord: CLLocationCoordinate2D)]] = [:]

        for entry in locatedSpots {
            let latKey = round(entry.coord.latitude / gridSize) * gridSize
            let lonKey = round(entry.coord.longitude / gridSize) * gridSize
            let key = "\(latKey),\(lonKey)"
            buckets[key, default: []].append(entry)
        }

        return buckets.values.compactMap { entries -> SpotCluster? in
            guard entries.count >= 2 else { return nil }

            let lats = entries.map(\.coord.latitude)
            let lons = entries.map(\.coord.longitude)
            let centerLat = lats.reduce(0, +) / Double(lats.count)
            let centerLon = lons.reduce(0, +) / Double(lons.count)

            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

            // Radius: base of 800 m + 200 m per additional spot, capped at 5000 m.
            let baseRadius: Double = 800
            let perSpotRadius: Double = 200
            let maxRadius: Double = 5000
            let radius = min(baseRadius + perSpotRadius * Double(entries.count - 2), maxRadius)

            return SpotCluster(center: center, radius: radius, count: entries.count)
        }
    }
}
