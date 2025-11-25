//
//  HealthKitDataManager.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 10/26/25.
//

import Foundation
import HealthKit

// MARK: - Health Metric Types

enum HealthMetricType {
    case steps
    case timeInBed
    case activeEnergy
    case exerciseTime
    case standHours
    case daylightTime
    case distanceWalking
    case flightsClimbed
    case restingHeartRate
    
    var quantityType: HKQuantityType? {
        switch self {
            case .steps:
                return HKQuantityType(.stepCount)
            case .timeInBed:
                return nil
            case .activeEnergy:
                return HKQuantityType(.activeEnergyBurned)
            case .exerciseTime:
                return HKQuantityType(.appleExerciseTime)
            case .standHours:
                return nil
            case .daylightTime:
                return HKQuantityType(.timeInDaylight)
            case .distanceWalking:
                return HKQuantityType(.distanceWalkingRunning)
            case .flightsClimbed:
                return HKQuantityType(.flightsClimbed)
            case .restingHeartRate:
                return HKQuantityType(.restingHeartRate)
        }
    }
    
    var unit: HKUnit {
        switch self {
            case .steps, .flightsClimbed:
                return .count()
            case .timeInBed, .exerciseTime, .daylightTime, .standHours:
                return .minute()
            case .activeEnergy:
                return .kilocalorie()
            case .distanceWalking:
                return .meter()
            case .restingHeartRate:
                return HKUnit.count().unitDivided(by: .minute())
        }
    }
}

// MARK: - Health Metrics Result

struct HealthMetrics: Equatable {
    let stepsToday: Double
    let timeInBedLastNight: Double // minutes
    let activeEnergyToday: Double // kcal
    let exerciseMinutesToday: Double
    let standHoursToday: Double
    let daylightTimeToday: Double // minutes
    let distanceWalkingToday: Double // meters
    let flightsClimbedToday: Double
    let restingHeartRateToday: Double // bpm
    
    // Activity Ring Progress (0.0 to 1.0+)
    var moveRingProgress: Double {
        // Assuming a 500 kcal goal; ideally fetch from HKActivitySummary
        activeEnergyToday / 500.0
    }
    
    var exerciseRingProgress: Double {
        exerciseMinutesToday / 60.0
    }
    
    var standRingProgress: Double {
        standHoursToday / 12.0
    }
}

// MARK: - Health Metrics Manager

class HealthMetricsManager {
    private let healthStore: HKHealthStore
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Public API
    
    func fetchAllMetrics(for date: Date) async throws -> HealthMetrics {
        async let steps = fetchMetricForDay(for: date, metricType: .steps)
        async let timeInBed = fetchTimeInBed(for: date)
        async let activeEnergy = fetchMetricForDay(for: date, metricType: .activeEnergy)
        async let exerciseTime = fetchMetricForDay(for: date, metricType: .exerciseTime)
        async let standHours = fetchStandHours(for: date)
        async let daylightTime = fetchMetricForDay(for: date, metricType: .daylightTime)
        async let distance = fetchMetricForDay(for: date, metricType: .distanceWalking)
        async let flights = fetchMetricForDay(for: date, metricType: .flightsClimbed)
        async let restingHR = fetchRestingHeartRate(for: date)
        
        return try await HealthMetrics(
            stepsToday: steps,
            timeInBedLastNight: timeInBed,
            activeEnergyToday: activeEnergy,
            exerciseMinutesToday: exerciseTime,
            standHoursToday: standHours,
            daylightTimeToday: daylightTime,
            distanceWalkingToday: distance,
            flightsClimbedToday: flights,
            restingHeartRateToday: restingHR
        )
    }
    
    // MARK: - Individual Metric Functions
    
    /// Fetches today's value for a given metric type
    func fetchMetricForDay(for date: Date, metricType: HealthMetricType) async throws -> Double {
        guard let quantityType = metricType.quantityType else {
            throw HealthMetricsError.invalidMetricType
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        return try await fetchCumulativeSum(
            quantityType: quantityType,
            unit: metricType.unit,
            start: startOfDay,
            end: date
        )
    }
    
    /// Fetches time in bed for last night (previous sleep period)
    func fetchTimeInBed(for date: Date) async throws -> Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        // Look back from start of today to 24 hours prior to capture last night's sleep
        let endOfYesterday = startOfToday
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfYesterday,
                end: endOfYesterday,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                // Filter for "inBed" samples
                let inBedSamples = samples.filter { sample in
                    sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }
                
                let totalMinutes = inBedSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                }
                
                continuation.resume(returning: totalMinutes)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch stand hours from activity summary
    func fetchStandHours(for date: Date) async throws -> Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfToday,
                end: date,
                options: .strictStartDate
            )
            
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let summary = summaries?.first else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let standHours = Double(summary.appleStandHours.doubleValue(for: .count()))
                continuation.resume(returning: standHours)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetches today's resting heart rate (returns nil if not available)
    func fetchRestingHeartRate(for date: Date) async throws -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthMetricsError.invalidMetricType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: date.startOfDay,
                end: date,
                options: .strictStartDate
            )
            
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate,
                ascending: false
            )
            
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Private Helper Functions
    
    /// Generic function to fetch cumulative sum for quantity types
    private func fetchCumulativeSum(
        quantityType: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: .strictStartDate
            )
            
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Error Handling

enum HealthMetricsError: LocalizedError {
    case invalidMetricType
    case authorizationDenied
    case dataNotAvailable
    
    var errorDescription: String? {
        switch self {
            case .invalidMetricType:
                return "The specified health metric type is not valid"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            case .dataNotAvailable:
                return "The requested health data is not available"
        }
    }
}

// MARK: - Authorization Helper

extension HealthMetricsManager {
    /// Requests authorization for all metrics
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime),
            HKQuantityType(.timeInDaylight),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.flightsClimbed),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis),
            HKActivitySummaryType.activitySummaryType()
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
}
