import Foundation
import MapKit

class OfflineTileOverlay: MKTileOverlay {
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let x = path.x
        let y = path.y
        let z = path.z
        
        Task {
            do {
                let data = try await MapTileManager.shared.downloadTile(x: x, y: y, z: z)
                result(data, nil)
            } catch {
                print("Error loading tile at \(z)/\(x)/\(y): \(error)")
                result(nil, error)
            }
        }
    }
}
