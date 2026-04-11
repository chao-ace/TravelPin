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

    /// Real-time weather info for the active travel.
    @Published var currentWeather: WeatherInfo? = nil

    private let healthStore = HKHealthStore()
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()

    private init() {
        self.activeRecommendation = nil
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

    func fetchStepCount() async -> Int {
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

    /// Fetches weather for a single coordinate and returns a WeatherInfo (for NowPlaying / check-in use).
    func fetchWeatherForSpot(coord: CLLocationCoordinate2D) async -> WeatherInfo? {
        guard let weather = await fetchWeather(for: coord) else { return nil }
        let current = weather.currentWeather
        return WeatherInfo(
            temperature: current.temperature.value,
            condition: current.condition.description,
            isRainy: current.condition.description.contains("Rain") || current.condition.description.contains("雨"),
            hourlyForecast: weather.hourlyForecast.prefix(6).map { forecast in
                HourForecast(
                    time: forecast.date,
                    temperature: forecast.temperature.value,
                    condition: forecast.condition.description,
                    precipitationChance: forecast.precipitationChance
                )
            }
        )
    }

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

    // MARK: - Real-time Weather for Travel

    /// Fetch current weather for the travel's first spot and update `currentWeather`.
    func fetchWeatherForTravel(_ travel: Travel) async {
        guard let coordinate = travel.spots.first?.coordinate else { return }
        guard let weather = await fetchWeather(for: coordinate) else { return }

        let current = weather.currentWeather
        let temp = current.temperature.value
        let condition = current.condition.description
        let isRainy = current.precipitationIntensity.value > 0

        // Get hourly forecast for the next 24 hours
        let hourlyForecast = Array(weather.hourlyForecast.prefix(24))
        let hourly = hourlyForecast.map { hour in
            HourForecast(
                time: hour.date,
                temperature: hour.temperature.value,
                condition: hour.condition.description,
                precipitationChance: hour.precipitationChance
            )
        }

        await MainActor.run {
            self.currentWeather = WeatherInfo(
                temperature: temp,
                condition: condition,
                isRainy: isRainy,
                hourlyForecast: hourly
            )
        }
    }

    // MARK: - Smart Packing Hints

    /// Generate packing hints based on destination weather analysis.
    func generateSmartPackingHints(for travel: Travel) async -> [String] {
        guard let coordinate = travel.spots.first?.coordinate else {
            return defaultPackingHints(for: travel)
        }

        guard let weather = await fetchWeather(for: coordinate) else {
            return defaultPackingHints(for: travel)
        }

        let dailyForecast = Array(weather.dailyForecast.prefix(7))
        let temp = dailyForecast.map { $0.highTemperature.value }
        let avgTemp = temp.isEmpty ? 20 : temp.reduce(0, +) / Double(temp.count)
        let hasRain = dailyForecast.contains { day in
            day.precipitationChance > 0.3
        }

        var hints: [String] = []

        // Temperature-based suggestions
        if avgTemp < 10 {
            hints += ["luggage.tpl.jacket".localized, "luggage.tpl.socks".localized, "厚围巾", "保暖内衣"]
        } else if avgTemp > 30 {
            hints += ["防晒霜", "luggage.tpl.sunglasses".localized, "luggage.tpl.bottle".localized, "遮阳帽"]
        } else if avgTemp > 20 {
            hints += ["luggage.tpl.tshirt".localized, "luggage.tpl.pants".localized]
        }

        // Rain-based suggestions
        if hasRain {
            hints += ["luggage.tpl.umbrella".localized, "一次性雨衣", "防水手机袋"]
        }

        // Travel type suggestions
        switch travel.type {
        case .concert:
            hints += ["luggage.tpl.earphones".localized, "luggage.tpl.powerbank".localized, "荧光棒"]
        case .chill:
            hints += ["luggage.tpl.sunglasses".localized, "luggage.tpl.bottle".localized, "沙滩巾"]
        case .business:
            hints += ["正装", "luggage.tpl.laptop".localized, "名片夹"]
        default:
            break
        }

        return hints
    }

    private func defaultPackingHints(for travel: Travel) -> [String] {
        var hints = ["luggage.tpl.passport".localized, "luggage.tpl.charger".localized, "luggage.tpl.medicine".localized]
        switch travel.type {
        case .concert: hints += ["luggage.tpl.earphones".localized, "luggage.tpl.powerbank".localized]
        case .chill: hints += ["luggage.tpl.sunglasses".localized, "luggage.tpl.bottle".localized]
        case .business: hints += ["luggage.tpl.laptop".localized, "正装"]
        default: break
        }
        return hints
    }
}

// MARK: - Weather Info Model

struct WeatherInfo {
    let temperature: Double
    let condition: String
    let isRainy: Bool
    let hourlyForecast: [HourForecast]
}

struct HourForecast {
    let time: Date
    let temperature: Double
    let condition: String
    let precipitationChance: Double // 0.0 - 1.0
}
