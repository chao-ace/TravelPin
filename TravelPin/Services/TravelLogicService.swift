import Foundation
import SwiftData
import CoreLocation

/// Service responsible for analyzing travel data and detecting logical inconsistencies.
struct TravelLogicService {
    
    // MARK: - Validation Result
    
    struct LogicAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let severity: Severity
        let relatedSpotIds: [UUID]
        
        enum Severity {
            case info, warning, critical
        }
    }
    
    // MARK: - Logic Blueprint Analysis (Pre-travel)
    
    /// Analyzes a travel plan for logical conflicts like time overlaps or spatial impossibilities.
    static func analyze(_ travel: Travel) -> [LogicAlert] {
        var alerts: [LogicAlert] = []
        
        // 1. Check for overlapping spots chronologically
        for itinerary in travel.itineraries {
            let daySpots = itinerary.spots.sorted { 
                ($0.estimatedDate ?? Date.distantPast) < ($1.estimatedDate ?? Date.distantPast) 
            }
            
            for i in 0..<daySpots.count {
                let current = daySpots[i]
                
                // Temporal Check
                if i + 1 < daySpots.count {
                    let next = daySpots[i+1]
                    if let start1 = current.estimatedDate, 
                       let duration = current.visitDuration,
                       let start2 = next.estimatedDate {
                        
                        let end1 = start1.addingTimeInterval(TimeInterval(duration * 60))
                        
                        // Overlap detection
                        if end1 > start2 {
                            alerts.append(LogicAlert(
                                title: "行程重叠".localized,
                                message: "\(current.name) 与 \(next.name) 的时间安排存在重叠，请检查。".localized,
                                severity: .warning,
                                relatedSpotIds: [current.id, next.id]
                            ))
                        }
                        
                        // Spatial Check (Simple Distance/Time check)
                        if let coord1 = current.coordinate, let coord2 = next.coordinate {
                            let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
                            let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
                            let distance = loc1.distance(from: loc2) / 1000.0 // km
                            
                            let timeBetween = start2.timeIntervalSince(end1) / 60.0 // minutes
                            
                            // If distance > 5km and time between < 15 mins, or impossible speeds
                            if distance > 2.0 && timeBetween < 10 {
                                alerts.append(LogicAlert(
                                    title: "交通逻辑预警".localized,
                                    message: "\(current.name) 到 \(next.name) 的距离为 \(String(format: "%.1f", distance))km，预留换乘时间不足。".localized,
                                    severity: .info,
                                    relatedSpotIds: [current.id, next.id]
                                ))
                            }
                        }
                    }
                }
            }
        }
        
        return alerts
    }
    
    // MARK: - Active Pulse Logic (During-travel)
    
    /// Finds the "current" and "next" focus spots for an active trip.
    static func getFocus(for travel: Travel) -> (current: Spot?, next: Spot?) {
        let now = Date()
        let activeSpots = travel.spots.filter { $0.status != .travelled && $0.status != .cancelled }
            .sorted { ($0.estimatedDate ?? Date.distantFuture) < ($1.estimatedDate ?? Date.distantFuture) }
        
        var current: Spot?
        var next: Spot?
        
        for spot in activeSpots {
            guard let estimated = spot.estimatedDate else { continue }
            
            let duration = TimeInterval((spot.visitDuration ?? 60) * 60)
            let end = estimated.addingTimeInterval(duration)
            
            if now >= estimated && now <= end {
                current = spot
            } else if now < estimated && next == nil {
                next = spot
            }
        }
        
        // If no spot is exactly "current" by time, take the first upcoming one as next
        if current == nil && next == nil && !activeSpots.isEmpty {
            next = activeSpots.first
        }
        
        return (current, next)
    }
    
    // MARK: - Insight Data (Post-travel)
    
    struct TripInsight {
        let totalCost: Double
        let budget: Double?
        let distanceTravelled: Double // km
        let spotTypeDistribution: [SpotType: Int]
        let completionRate: Double
        
        /// Economic indicator: Cost per kilometer.
        var costPerKm: Double {
            distanceTravelled > 0 ? totalCost / distanceTravelled : 0
        }
        
        /// Budget utilization ratio (0.0 - 1.0+).
        var budgetUtilization: Double? {
            guard let b = budget, b > 0 else { return nil }
            return totalCost / b
        }
    }
    
    static func generateInsight(for travel: Travel) -> TripInsight {
        let totalCost = travel.totalSpent
        
        // Detailed distance calculation (point to point sequence)
        var totalDistance = 0.0
        let visitedSpots = travel.spots.filter { $0.isVisited }.sorted { ($0.actualDate ?? Date.distantPast) < ($1.actualDate ?? Date.distantPast) }
        
        for i in 0..<visitedSpots.count {
            if i + 1 < visitedSpots.count {
                if let c1 = visitedSpots[i].coordinate, let c2 = visitedSpots[i+1].coordinate {
                    let l1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
                    let l2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
                    totalDistance += l1.distance(from: l2) / 1000.0
                }
            }
        }
        
        var distribution: [SpotType: Int] = [:]
        for spot in travel.spots {
            distribution[spot.type, default: 0] += 1
        }
        
        let completionRate = travel.spots.isEmpty ? 0 : Double(travel.visitedSpotCount) / Double(travel.spots.count)
        
        return TripInsight(
            totalCost: totalCost,
            budget: travel.budget,
            distanceTravelled: totalDistance,
            spotTypeDistribution: distribution,
            completionRate: completionRate
        )
    }

    // MARK: - Auto Status Transition

    /// Automatically transitions travel status based on current date:
    /// - Planning → Traveling when today falls within [startDate, endDate]
    /// - Traveling → Travelled when endDate has passed
    static func autoTransitionStatus(travels: [Travel], context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())

        for travel in travels {
            let start = Calendar.current.startOfDay(for: travel.startDate)
            let end = Calendar.current.startOfDay(for: travel.endDate)

            switch travel.status {
            case .planning:
                if today >= start && today <= end {
                    travel.status = .traveling
                }
            case .traveling:
                if today > end {
                    travel.status = .travelled
                }
            default:
                break
            }
        }

        try? context.save()
    }
}
