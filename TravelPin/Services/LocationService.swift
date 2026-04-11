import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()

    @Published var checkedInSpot: Spot?
    @Published var isMonitoring: Bool = false
    @Published var currentLocation: CLLocation?

    private var monitoredSpots: [UUID: Spot] = [:]
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Geocoding

    func geocode(address: String) async throws -> CLLocationCoordinate2D? {
        let placemarks = try await geocoder.geocodeAddressString(address)
        return placemarks.first?.location?.coordinate
    }

    // MARK: - Route Calculation (Automobile)

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

    // MARK: - Route Calculation (Walking)

    func calculateWalkingRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            print("Error calculating walking route: \(error)")
            return nil
        }
    }

    // MARK: - Spot Arrival Monitoring

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoring(spots: [Spot]) {
        let authorized = locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
        guard authorized else {
            requestLocationPermission()
            return
        }

        // Stop all existing monitoring
        stopMonitoringAll()

        for spot in spots {
            guard let coord = spot.coordinate else { continue }
            let region = CLCircularRegion(
                center: coord,
                radius: 200,
                identifier: spot.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
            monitoredSpots[spot.id] = spot
        }

        isMonitoring = !monitoredSpots.isEmpty
        if isMonitoring {
            locationManager.startUpdatingLocation()
        }
    }

    func stopMonitoringAll() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredSpots.removeAll()
        isMonitoring = false
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let spotId = UUID(uuidString: region.identifier) else { return }

        Task { @MainActor in
            guard let spot = self.monitoredSpots[spotId] else { return }
            self.checkedInSpot = spot
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    // MARK: - Smart Route Optimization

    /// Optimize the visiting order of spots using nearest-neighbor + 2-opt improvement.
    /// Returns spots sorted in optimal visiting order.
    func optimizeRoute(spots: [Spot]) -> [Spot] {
        let located = spots.filter { $0.hasLocation }
        guard located.count >= 3 else { return spots }

        // Step 1: Nearest-neighbor heuristic starting from first spot
        var route = nearestNeighborRoute(spots: located)

        // Step 2: 2-opt improvement (limited iterations for performance)
        route = twoOptImprove(route: route, maxIterations: 20)

        // Step 3: Preserve non-located spots at the end
        let nonLocated = spots.filter { !$0.hasLocation }
        return route + nonLocated
    }

    /// Optimize route asynchronously with real distance calculations via MapKit.
    func optimizeRouteWithDistances(spots: [Spot]) async -> [Spot] {
        let located = spots.filter { $0.hasLocation }
        guard located.count >= 3 else { return spots }

        // Build distance matrix using MapKit
        let distanceMatrix = await buildDistanceMatrix(for: located)

        // Nearest-neighbor with real distances
        var route = nearestNeighborRoute(spots: located, distances: distanceMatrix)

        // 2-opt with real distances
        route = twoOptImprove(route: route, distances: distanceMatrix, maxIterations: 10)

        let nonLocated = spots.filter { !$0.hasLocation }
        return route + nonLocated
    }

    // MARK: - Route Optimization Helpers

    private func nearestNeighborRoute(spots: [Spot], distances: [[Double]]? = nil) -> [Spot] {
        guard !spots.isEmpty else { return [] }

        var unvisited = spots
        var route: [Spot] = []
        var current = unvisited.removeFirst()
        route.append(current)

        while !unvisited.isEmpty {
            let currentCoord = current.coordinate
            var nearestIndex = 0
            var nearestDistance = Double.infinity

            for (index, spot) in unvisited.enumerated() {
                let distance: Double
                if let distances, let currentIdx = spots.firstIndex(where: { $0.id == current.id }),
                   let spotIdx = spots.firstIndex(where: { $0.id == spot.id }) {
                    distance = distances[currentIdx][spotIdx]
                } else if let coord = spot.coordinate, let currentCoord {
                    distance = euclideanDistance(from: currentCoord, to: coord)
                } else {
                    distance = Double.infinity
                }

                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestIndex = index
                }
            }

            current = unvisited.remove(at: nearestIndex)
            route.append(current)
        }

        return route
    }

    private func twoOptImprove(route: [Spot], distances: [[Double]]? = nil, maxIterations: Int = 20) -> [Spot] {
        var improved = route
        var iteration = 0

        while iteration < maxIterations {
            var bestGain = 0.0
            var bestI = 0
            var bestJ = 0

            for i in 0..<(improved.count - 1) {
                for j in (i + 2)..<improved.count {
                    let gain = calculateSwapGain(route: improved, i: i, j: j, distances: distances)
                    if gain > bestGain {
                        bestGain = gain
                        bestI = i
                        bestJ = j
                    }
                }
            }

            if bestGain > 0 {
                // Reverse the segment between i and j
                improved.reverseSubrange(bestI + 1...bestJ)
            } else {
                break
            }
            iteration += 1
        }

        return improved
    }

    private func calculateSwapGain(route: [Spot], i: Int, j: Int, distances: [[Double]]?) -> Double {
        let a = route[i]
        let b = route[i + 1]
        let c = route[j]
        let d = j + 1 < route.count ? route[j + 1] : nil

        let distAB = distanceBetween(a, b, in: route, distances: distances)
        let distCD = d.map { distanceBetween(c, $0, in: route, distances: distances) } ?? 0
        let distAC = distanceBetween(a, c, in: route, distances: distances)
        let distBD = d.map { distanceBetween(b, $0, in: route, distances: distances) } ?? 0

        return (distAB + distCD) - (distAC + distBD)
    }

    private func distanceBetween(_ a: Spot, _ b: Spot, in route: [Spot], distances: [[Double]]?) -> Double {
        if let distances,
           let aIdx = route.firstIndex(where: { $0.id == a.id }),
           let bIdx = route.firstIndex(where: { $0.id == b.id }) {
            return distances[aIdx][bIdx]
        }
        if let coordA = a.coordinate, let coordB = b.coordinate {
            return euclideanDistance(from: coordA, to: coordB)
        }
        return Double.infinity
    }

    private func euclideanDistance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    private func buildDistanceMatrix(for spots: [Spot]) async -> [[Double]] {
        let count = spots.count
        var matrix = Array(repeating: Array(repeating: Double.infinity, count: count), count: count)

        for i in 0..<count {
            matrix[i][i] = 0
            for j in (i + 1)..<count {
                guard let coordA = spots[i].coordinate, let coordB = spots[j].coordinate else { continue }
                let distance = euclideanDistance(from: coordA, to: coordB)
                matrix[i][j] = distance
                matrix[j][i] = distance
            }
        }

        return matrix
    }
}

// MARK: - Array Extension

private extension Array {
    mutating func reverseSubrange(_ range: ClosedRange<Int>) {
        var left = range.lowerBound
        var right = range.upperBound
        while left < right {
            swapAt(left, right)
            left += 1
            right -= 1
        }
    }
}
