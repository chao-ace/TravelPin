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

    private init() {}

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
                        title: "注意休息",
                        subtitle: "今天已经走了 \(steps) 步，要不要找个安静的咖啡馆坐一会儿？",
                        actionType: .discoverRemote,
                        internalSpotID: nil,
                        remoteSpotName: "安静咖啡馆"
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
                            self.activeRecommendation = IntelligenceRecommendation(
                                trigger: .weather(condition: condition, spotName: nextOutdoorSpot.name),
                                title: "下雨了",
                                subtitle: "检测到 \(nextOutdoorSpot.name) 附近有雨（\(Int(temperature.value))°C）。要不要先去 \(indoorSpot?.name ?? "室内景点")？",
                                actionType: indoorSpot != nil ? .swapLocal : .discoverRemote,
                                internalSpotID: indoorSpot?.id,
                                remoteSpotName: indoorSpot == nil ? "室内活动" : nil
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
        print("Swapping to Spot: \(targetSpotID)")
        self.activeRecommendation = nil
    }

    func dismiss() {
        self.activeRecommendation = nil
    }
}
