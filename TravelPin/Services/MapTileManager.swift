import Foundation
import MapKit

class MapTileManager {
    static let shared = MapTileManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    var cacheDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("MapTiles")
    }
    
    func setupCache() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func tileURL(x: Int, y: Int, z: Int) -> URL {
        return URL(string: "https://tile.openstreetmap.org/\(z)/\(x)/\(y).png")!
    }
    
    func localTileURL(x: Int, y: Int, z: Int) -> URL {
        return cacheDirectory.appendingPathComponent("\(z)/\(x)/\(y).png")
    }
    
    func downloadTile(x: Int, y: Int, z: Int) async throws -> Data {
        let localURL = localTileURL(x: x, y: y, z: z)
        
        if fileManager.fileExists(atPath: localURL.path) {
            return try Data(contentsOf: localURL)
        }
        
        let remoteURL = tileURL(x: x, y: y, z: z)
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        
        // Save to local
        let directory = localURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try data.write(to: localURL)
        
        return data
    }
    
    // Download a region for a specific zoom level
    func downloadRegion(_ region: MKCoordinateRegion, zoomRange: ClosedRange<Int>) async {
        // Implementation for calculating tile bounds based on lat/long and zoom...
        // This is a simplified placeholder for the "Full Package" logic.
        print("Starting bulk download for region \(region.center)")
    }
}
