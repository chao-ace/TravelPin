import Foundation
import SwiftUI
import WeatherKit
import HealthKit
import CoreLocation
import Combine

enum IntelligenceTrigger {
    case weather(condition: String, spotName: String)
    case fatigue(steps: Int)
    case distance(meters: Double)
}

struct IntelligenceRecommendation: Identifiable {
    let id = UUID()
    let trigger: IntelligenceTrigger
    let title: String
    let subtitle: String
    let actionType: ActionType
    let internalSpotID: UUID?
    let remoteSpotName: String?

    enum ActionType {
        case swapLocal
        case discoverRemote
    }
}

class IntelligenceService: ObservableObject {
    static let shared = IntelligenceService()

    @Published var activeRecommendation: IntelligenceRecommendation? = nil
    @Published var healthAuthorized: Bool = false
    @Published var locationAuthorized: Bool = false

    private let healthStore = HKHealthStore()
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()

    private init() {
        // Debug Tip: Pre-set a recommendation to verify the Blue UI
        self.activeRecommendation = IntelligenceRecommendation(
            trigger: .distance(meters: 100),
            title: "行程优化中",
            subtitle: "当前位置步行 5 分钟可到达热门景点，是否加入行程？",
            actionType: .discoverRemote,
            internalSpotID: nil,
            remoteSpotName: "附近景点"
        )
    }

    // MARK: - Permission Requests

    func requestHealthPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let stepType = HKQuantityType(.stepCount)
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            healthAuthorized = true
            return true
        } catch {
            print("HealthKit auth failed: \(error)")
            return false
        }
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationAuthorized = locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
    }

    // MARK: - Main Vibe Check

    func performVibeCheck(for travel: Travel) {
        Task {
            // 1. Fatigue Check (HealthKit)
            let steps = await fetchStepCount()
            if steps > 15000 {
                await MainActor.run {
                    self.activeRecommendation = IntelligenceRecommendation(
                        trigger: .fatigue(steps: steps),
                        title: "intel.fatigue.title".localized,
                        subtitle: String(format: "intel.fatigue.subtitle".localized, steps),
                        actionType: .discoverRemote,
                        internalSpotID: nil,
                        remoteSpotName: "intel.weather.rain.indoor".localized
                    )
                }
                return
            }

            // 2. Weather Check (WeatherKit)
            guard let coordinate = travel.spots.first?.coordinate else { return }
            let weather = await fetchWeather(for: coordinate)

            if let weather {
                let isRainy = weather.currentWeather.precipitationIntensity.value > 0
                let condition = weather.currentWeather.condition.description
                let temperature = weather.currentWeather.temperature

                if isRainy {
                    if let nextOutdoorSpot = travel.spots.first(where: { $0.status == .planning && $0.type == .sightseeing }) {
                        let indoorSpot = travel.spots.first(where: { $0.status == .planning && ($0.type == .food || $0.type == .shopping) })

                        await MainActor.run {
                            let indoorName = indoorSpot?.name ?? "intel.weather.rain.indoor".localized
                            let subtitle = String(format: "intel.weather.rain.subtitle".localized, nextOutdoorSpot.name, Int(temperature.value), indoorName)
                            
                            self.activeRecommendation = IntelligenceRecommendation(
                                trigger: .weather(condition: condition, spotName: nextOutdoorSpot.name),
                                title: "intel.weather.rain.title".localized,
                                subtitle: subtitle,
                                actionType: indoorSpot != nil ? .swapLocal : .discoverRemote,
                                internalSpotID: indoorSpot?.id,
                                remoteSpotName: indoorSpot == nil ? "intel.weather.rain.indoor".localized : nil
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - HealthKit

    private func fetchStepCount() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }

        let stepType = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let result, let sum = result.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - WeatherKit

    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async -> Weather? {
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return try await weatherService.weather(for: location)
        } catch {
            print("Weather fetch failed: \(error)")
            return nil
        }
    }

    // MARK: - Actions

    func applySwap(in travel: Travel, targetSpotID: UUID) {
        // Find the spot and move it to 'traveling' or 'travelled' to manifest the plan change
        if let spot = travel.spots.first(where: { $0.id == targetSpotID }) {
            spot.status = .traveling
            spot.actualDate = Date()
            
            // If it's linked to an itinerary, mark it as high priority (logical concept)
            spot.sequence = 0 
        }
        
        self.activeRecommendation = nil
    }

    func discoverSomethingNew() {
        AppState.shared.navigateToDiscover()
        self.activeRecommendation = nil
    }

    func dismiss() {
        self.activeRecommendation = nil
    }
}
