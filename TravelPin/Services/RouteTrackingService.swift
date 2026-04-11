import Foundation
import CoreLocation
import SwiftUI
import Combine
import SwiftData

// MARK: - Route Tracking Service

/// Automatically records GPS waypoints during active trips for route replay.
@MainActor
final class RouteTrackingService: NSObject, ObservableObject {
    static let shared = RouteTrackingService()

    @Published var isTracking = false
    @Published var currentRoute: [RouteWaypoint] = []
    @Published var totalDistance: Double = 0 // meters

    private let locationManager = CLLocationManager()
    private var activeTravelId: UUID?
    private var lastRecordedLocation: CLLocation?
    private let minimumDistance: Double = 20 // meters between waypoints
    private let maxWaypointsPerRoute = 2000

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    // MARK: - Start / Stop

    func startTracking(for travel: Travel) {
        guard !isTracking else { return }
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            locationManager.requestAlwaysAuthorization()
            return
        }

        activeTravelId = travel.id
        currentRoute = []
        totalDistance = 0
        lastRecordedLocation = nil
        isTracking = true
        // Only set background updates when actually tracking and authorized for always
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.startUpdatingLocation()
    }

    func stopTracking(context: ModelContext) {
        guard isTracking else { return }
        locationManager.stopUpdatingLocation()
        isTracking = false

        // Persist route to the travel's route data
        if let travelId = activeTravelId {
            saveRoute(for: travelId, context: context)
        }

        activeTravelId = nil
    }

    // MARK: - Route Persistence

    private func saveRoute(for travelId: UUID, context: ModelContext) {
        guard !currentRoute.isEmpty else { return }

        let descriptor = FetchDescriptor<Travel>(predicate: #Predicate { $0.id == travelId })
        guard let travel = try? context.fetch(descriptor).first else { return }

        let routeData = currentRoute.map { waypoint -> [String: Double] in
            return ["lat": waypoint.coordinate.latitude, "lng": waypoint.coordinate.longitude, "ts": waypoint.timestamp.timeIntervalSince1970]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: routeData) {
            travel.routeData = jsonData
            try? context.save()
        }
    }

    /// Load a previously saved route for replay.
    func loadRoute(for travel: Travel) -> [RouteWaypoint] {
        guard let data = travel.routeData else { return [] }
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]] else { return [] }

        return array.compactMap { dict in
            guard let lat = dict["lat"], let lng = dict["lng"], let ts = dict["ts"] else { return nil }
            return RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                timestamp: Date(timeIntervalSince1970: ts)
            )
        }
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate

extension RouteTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            guard self.isTracking else { return }

            let newLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

            // Filter by minimum distance
            if let last = self.lastRecordedLocation {
                let distance = last.distance(from: newLocation)
                guard distance >= self.minimumDistance else { return }
                self.totalDistance += distance
            }

            let waypoint = RouteWaypoint(
                coordinate: location.coordinate,
                timestamp: location.timestamp
            )

            self.currentRoute.append(waypoint)
            self.lastRecordedLocation = newLocation

            // Trim if too many waypoints
            if self.currentRoute.count > self.maxWaypointsPerRoute {
                self.currentRoute.removeFirst(self.currentRoute.count - self.maxWaypointsPerRoute)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[RouteTracking] Location error: \(error.localizedDescription)")
    }
}

// MARK: - Route Waypoint Model

struct RouteWaypoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

// MARK: - Travel Route Data Extension

private var routeDataKey: UInt8 = 0

extension Travel {
    var routeData: Data? {
        get {
            objc_getAssociatedObject(self, &routeDataKey) as? Data
        }
        set {
            objc_setAssociatedObject(self, &routeDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
