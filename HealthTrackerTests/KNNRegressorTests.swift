//
//  KNNRegressorTests.swift
//  KNNRegressorTests
//
//  Created by Arthur Efremenko on 11/25/25.
//

import Testing
@testable import HealthTracker

struct FeatureScalerTests {
    let data: [SatisfactionEntry]
    
    init() {
        do {
            data = try loadTestDataFromFile(named: "SampleData")
        } catch {
            fatalError("Could not load test data: \(error)")
        }
    }
    
    @Test func testFit() async throws {
        let testData = [
            [10.0, 20.0, 30.0],
            [20.0, 40.0, 60.0],
            [30.0, 60.0, 90.0]
        ]
        
        let scaler = FeatureScaler()
        
        scaler.fit(testData)
        
        // Verified with a calculator:
        // feature 0: mean = 20, std = 8.165
        // feature 1: mean = 40, std = 16.33
        // feature 2: mean = 60, std = 24.49
        
        let transformed = scaler.transform([20.0, 40.0, 60.0])
        
        // Exact means, should all be at or about 0
        #expect(abs(transformed[0]) < 0.001)
        #expect(abs(transformed[1]) < 0.001)
        #expect(abs(transformed[2]) < 0.001)
        
        let transformed2 = scaler.transform([10.0, 20.0, 30.0])
        
        // Smaller mean, should be below 0
        #expect(transformed2[0] < 0)
        
        // (10 - 20) / 8.165 = -1.225
        #expect(abs(transformed2[0] - (-1.225)) < 0.01)
    }
    
    @Test func testTransform() async throws {
        let testData = [
            [0.0, 0.0],
            [10.0, 20.0],
            [20.0, 40.0]
        ]
        
        let scaler = FeatureScaler()
        scaler.fit(testData)
        
        // Transform a new data point, means and std verified with a calculator
        // means = [10.0, 20.0]
        // std = [8.165, 16.33]
        let transformed = scaler.transform([15.0, 30.0])
        
        // Standardization formula: (x - mean) / std
        // (15 - 10) / 8.165 = 0.612
        // (30 - 20) / 16.33 = 0.612
        #expect(abs(transformed[0] - 0.612) < 0.01)
        #expect(abs(transformed[1] - 0.612) < 0.01)
        
        // Std = 0 edge case
        let constantData = [[5.0, 5.0], [5.0, 5.0], [5.0, 5.0]]
        let constantScaler = FeatureScaler()
        constantScaler.fit(constantData)
        let constantTransform = constantScaler.transform([5.0, 5.0])
        
        #expect(constantTransform[0] == 0.0)
        #expect(constantTransform[1] == 0.0)
    }
}

struct KNNRegressorTests {
    let data: [SatisfactionEntry]
    
    init() {
        do {
            data = try loadTestDataFromFile(named: "SampleData")
        } catch {
            fatalError("Could not load test data")
        }
    }
    
    @Test func testPredictSatisfactionScore() async throws {
        
    }
    
    @Test func testWeightedAverage() async throws {
        
    }
}
