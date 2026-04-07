import Foundation
import MapKit

class MapTileManager {
    static let shared = MapTileManager()

    private let fileManager = FileManager.default
    private let maxConcurrentDownloads = 4

    private init() {}

    // MARK: - Cache Directory

    var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("MapTiles")
    }

    var cacheSizeInBytes: Int {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += size
            }
        }
        return total
    }

    var cacheSizeDescription: String {
        let bytes = cacheSizeInBytes
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    func setupCache() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Tile URL Helpers

    func tileURL(x: Int, y: Int, z: Int) -> URL {
        return URL(string: "https://tile.openstreetmap.org/\(z)/\(x)/\(y).png")!
    }

    func localTileURL(x: Int, y: Int, z: Int) -> URL {
        return cacheDirectory.appendingPathComponent("\(z)/\(x)/\(y).png")
    }

    // MARK: - Single Tile Download

    func downloadTile(x: Int, y: Int, z: Int) async throws -> Data {
        let localURL = localTileURL(x: x, y: y, z: z)

        // Return cached tile if available
        if fileManager.fileExists(atPath: localURL.path) {
            return try Data(contentsOf: localURL)
        }

        let remoteURL = tileURL(x: x, y: y, z: z)
        var request = URLRequest(url: remoteURL)
        request.setValue("TravelPin/1.0", forHTTPHeaderField: "User-Agent") // OSM requires user-agent
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MapTileError.downloadFailed
        }

        // Save to local cache
        let directory = localURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try data.write(to: localURL)

        return data
    }

    // MARK: - Region Download (Bulk)

    /// Downloads all map tiles for a given coordinate region across the specified zoom range
    func downloadRegion(_ region: MKCoordinateRegion, zoomRange: ClosedRange<Int>) async -> Int {
        setupCache()
        var totalDownloaded = 0

        for zoom in zoomRange {
            let tiles = tileCoordinatesForRegion(region, zoom: zoom)
            // Download with concurrency limit
            try? await withThrowingTaskGroup(of: Void.self) { group in
                var activeCount = 0
                for tile in tiles {
                    if Task.isCancelled { break }
                    activeCount += 1
                    group.addTask {
                        _ = try await self.downloadTile(x: tile.x, y: tile.y, z: zoom)
                    }
                    if activeCount >= maxConcurrentDownloads {
                        try? await group.next()
                        activeCount -= 1
                        totalDownloaded += 1
                    }
                }
                // Wait for remaining
                for try await _ in group {
                    totalDownloaded += 1
                }
            }
        }

        return totalDownloaded
    }

    // MARK: - Tile Coordinate Calculation

    private struct TileCoord {
        let x: Int
        let y: Int
    }

    private func tileCoordinatesForRegion(_ region: MKCoordinateRegion, zoom: Int) -> [TileCoord] {
        let minTile = latLonToTile(lat: region.center.latitude + region.span.latitudeDelta / 2,
                                   lon: region.center.longitude - region.span.longitudeDelta / 2,
                                   zoom: zoom)
        let maxTile = latLonToTile(lat: region.center.latitude - region.span.latitudeDelta / 2,
                                   lon: region.center.longitude + region.span.longitudeDelta / 2,
                                   zoom: zoom)

        var tiles: [TileCoord] = []
        for x in minTile.x...maxTile.x {
            for y in minTile.y...maxTile.y {
                tiles.append(TileCoord(x: x, y: y))
            }
        }
        return tiles
    }

    private func latLonToTile(lat: Double, lon: Double, zoom: Int) -> TileCoord {
        let n = pow(2.0, Double(zoom))
        let x = Int((lon + 180.0) / 360.0 * n)
        let latRad = lat * .pi / 180.0
        let y = Int((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * n)
        return TileCoord(x: max(0, x), y: max(0, y))
    }

    // MARK: - Cache Management

    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        setupCache()
    }
}

enum MapTileError: LocalizedError {
    case downloadFailed
    case tileNotFound

    var errorDescription: String? {
        switch self {
        case .downloadFailed: return "地图瓦片下载失败，请检查网络连接"
        case .tileNotFound: return "未找到缓存的地图瓦片"
        }
    }
}
