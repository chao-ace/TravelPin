import Foundation
import MapKit

class MapCacheService {
    static let shared = MapCacheService()
    
    private init() {}
    
    func generateSnapshot(for coordinate: CLLocationCoordinate2D, size: CGSize = CGSize(width: 400, height: 300)) async -> Data? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        options.size = size
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        do {
            let snapshot = try await snapshotter.start()
            let image = snapshot.image
            return image.jpegData(compressionQuality: 0.8)
        } catch {
            print("Snapshot failed: \(error)")
            return nil
        }
    }
}
