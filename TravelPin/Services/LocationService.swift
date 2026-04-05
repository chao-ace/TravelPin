import Foundation
import CoreLocation
import MapKit

class LocationService {
    static let shared = LocationService()
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    func geocode(address: String) async throws -> CLLocationCoordinate2D? {
        let placemarks = try await geocoder.geocodeAddressString(address)
        return placemarks.first?.location?.coordinate
    }
    
    // Calculate route between points (Road-based)
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            print("Error calculating route: \(error)")
            return nil
        }
    }
}
