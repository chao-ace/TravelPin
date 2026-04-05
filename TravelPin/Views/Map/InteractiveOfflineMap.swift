import SwiftUI
import MapKit

struct InteractiveOfflineMap: UIViewRepresentable {
    @Bindable var travel: Travel
    @Binding var isOfflineMode: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        
        if isOfflineMode {
            let overlay = OfflineTileOverlay(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
            overlay.canReplaceMapContent = true
            uiView.addOverlay(overlay, level: .aboveLabels)
        }
        
        // Add markers and polylines
        updateAnnotations(for: uiView)
    }
    
    private func updateAnnotations(for mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = travel.spots.compactMap { spot -> MKPointAnnotation? in
            guard let coord = spot.coordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = spot.name
            return annotation
        }
        mapView.addAnnotations(annotations)
        
        // Polylines...
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
