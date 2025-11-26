//
//  LocalSearchOptimizerTests.swift
//  LocalSearchOptimizerTests
//
//  Created by Arthur Efremenko on 11/25/25.
//

import Foundation
import Testing
@testable import HealthTracker

struct LocalSearchOptimizerTests {
    let data: [SatisfactionEntry]
    
    init() {
        do {
            data = try loadTestDataFromFile(named: "SampleData")
        } catch {
            fatalError("Could not load test data")
        }
    }
    
    @Test func testOptimizationImprovesSatisfaction() throws {
        let lowActivityMetrics = [5000.0, 6.0, 400.0, 15.0, 7.0, 5.0, 4000.0, 8.0, 75.0]
        let initialSatisfaction = 5.0
         
        let initialParams = SatisfactionEntry(
            from: lowActivityMetrics,
            satisfactionScore: initialSatisfaction
        )!
        
        let optimizer = LocalSearchOptimizer(
            data: data,
            initialTemperature: 100.0,
            coolingRate: 0.95,
            stepSize: 0.1
        )
        
        print("\nOPTIMIZING FROM LOW VALUE")
        print("Initial satisfaction: \(String(format: "%.4f", initialSatisfaction))")
        print("Initial metrics: \(lowActivityMetrics)\n")
        
        let result = try optimizer.optimize(
            initialParams: initialParams,
            maxIterations: 2000
        )
        
        let finalSatisfaction = result.value.userSatisfactionScore!
        let finalMetrics = result.value.toList()
        
        print("\nRESULTS")
        print("Final satisfaction: \(String(format: "%.4f", finalSatisfaction))")
        print("Final metrics: \(finalMetrics)")
        print("Improvement: \(String(format: "%.4f", finalSatisfaction - initialSatisfaction))")
        print("History length: \(result.history.count)")
        
        #expect(finalSatisfaction > initialSatisfaction,
                "Optimization should improve satisfaction, found \(initialSatisfaction) to \(finalSatisfaction)")
        
        #expect(finalSatisfaction > 6.5,
                "Optimization should find parameters with satisfaction above 6.5, found \(finalSatisfaction)")
        
        #expect(result.history.count > 1,
                "Optimization history should contain multiple accepted states")
        
        #expect(finalSatisfaction >= 0.0 && finalSatisfaction <= 10.0,
                "Satisfaction score must be between 0 and 10")
    }
    
    @Test func testOptimizationWithHighStartingPoint() throws {
        let highActivityMetrics = [15000.0, 8.5, 1400.0, 75.0, 15.0, 10.0, 11500.0, 28.0, 55.0]
        let initialSatisfaction = 8.5
        
        let initialParams = SatisfactionEntry(
            from: highActivityMetrics,
            satisfactionScore: initialSatisfaction
        )!
        
        let optimizer = LocalSearchOptimizer(
            data: data,
            initialTemperature: 100.0,
            coolingRate: 0.95,
            stepSize: 0.1
        )
        
        print("\nOPTIMIZING FROM HIGH VALUE")
        print("Initial satisfaction: \(String(format: "%.4f", initialSatisfaction))")
        print("Initial metrics: \(highActivityMetrics)\n")
        
        let result = try optimizer.optimize(
            initialParams: initialParams,
            maxIterations: 2000
        )
        
        let finalSatisfaction = result.value.userSatisfactionScore!
        let finalMetrics = result.value.toList()
        
        print("\nRESULTS")
        print("Final satisfaction: \(String(format: "%.4f", finalSatisfaction))")
        print("Final metrics: \(finalMetrics)")
        print("Improvement: \(String(format: "%.4f", finalSatisfaction - initialSatisfaction))")
        print("History length: \(result.history.count)")
        
        #expect(finalSatisfaction >= initialSatisfaction,
                "Starting from high point, optimization should not go down")
        
        #expect(finalSatisfaction > 9.0,
                "Should maintain high satisfaction level, found \(finalSatisfaction)")
    }
    
    @Test func testErrorHandlingForMissingSatisfactionScore() async throws {
        let metrics = [10000.0, 7.5, 800.0, 45.0, 12.0, 8.0, 8000.0, 18.0, 65.0]
        let invalidParams = SatisfactionEntry(
            day: Date(),
            score: nil,
            stepsToday: metrics[0],
            timeInBedLastNight: metrics[1],
            activeEnergyToday: metrics[2],
            exerciseMinutesToday: metrics[3],
            standHoursToday: metrics[4],
            daylightTimeToday: metrics[5],
            distanceWalkingToday: metrics[6],
            flightsClimbedToday: metrics[7],
            restingHeartRateToday: metrics[8]
        )
        
        let optimizer = await LocalSearchOptimizer(data: data)
        
        #expect(throws: Error.self) {
            try optimizer.optimize(
                initialParams: invalidParams,
                maxIterations: 50
            )
        }
    }
}
