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
        updatePolylines(for: uiView)
    }
    
    private func updatePolylines(for mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays.filter { $0 is MKPolyline })
        
        let coords = travel.spots
            .sorted(by: { $0.sequence < $1.sequence })
            .compactMap { $0.coordinate }
        
        guard coords.count > 1 else { return }
        
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
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
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "SpotMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            annotationView?.markerTintColor = UIColor(Color.tpAccent)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            if !views.isEmpty {
                TPHaptic.impact(.light)
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            // Placeholder: Could trigger a notification or closure to navigate
            print("Tapped detail for: \(view.annotation?.title ?? "Unknown")")
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.tpAccent)
                renderer.lineWidth = 4
                renderer.lineDashPattern = [1, 10] // Dashed line for 'cinematic path'
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
