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
        
        let scaler = await FeatureScaler()
        
        await scaler.fit(testData)
        
        // Verified with a calculator:
        // feature 0: mean = 20, std = 8.165
        // feature 1: mean = 40, std = 16.33
        // feature 2: mean = 60, std = 24.49
        
        let transformed = await scaler.transform([20.0, 40.0, 60.0])
        
        // Exact means, should all be at or about 0
        #expect(abs(transformed[0]) < 0.001)
        #expect(abs(transformed[1]) < 0.001)
        #expect(abs(transformed[2]) < 0.001)
        
        let transformed2 = await scaler.transform([10.0, 20.0, 30.0])
        
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
        
        let scaler = await FeatureScaler()
        await scaler.fit(testData)
        
        // Transform a new data point, means and std verified with a calculator
        // means = [10.0, 20.0]
        // std = [8.165, 16.33]
        let transformed = await scaler.transform([15.0, 30.0])
        
        // Standardization formula: (x - mean) / std
        // (15 - 10) / 8.165 = 0.612
        // (30 - 20) / 16.33 = 0.612
        #expect(abs(transformed[0] - 0.612) < 0.01)
        #expect(abs(transformed[1] - 0.612) < 0.01)
        
        // Std = 0 edge case
        let constantData = [[5.0, 5.0], [5.0, 5.0], [5.0, 5.0]]
        let constantScaler = await FeatureScaler()
        await constantScaler.fit(constantData)
        let constantTransform = await constantScaler.transform([5.0, 5.0])
        
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
        let trainingData: [SatisfactionEntry] = [
            SatisfactionEntry(from: [10000.0, 8.0, 1000.0, 60.0, 12.0, 8.0, 8000.0, 20.0, 60.0], satisfactionScore: 8.0)!,
            SatisfactionEntry(from: [12000.0, 8.5, 1200.0, 70.0, 14.0, 9.0, 9000.0, 25.0, 58.0], satisfactionScore: 9.0)!,
            SatisfactionEntry(from: [5000.0, 6.0, 500.0, 20.0, 8.0, 5.0, 4000.0, 10.0, 75.0], satisfactionScore: 5.0)!,
            SatisfactionEntry(from: [6000.0, 6.5, 600.0, 25.0, 9.0, 6.0, 5000.0, 12.0, 72.0], satisfactionScore: 6.0)!,
            SatisfactionEntry(from: [15000.0, 9.0, 1500.0, 80.0, 15.0, 10.0, 11000.0, 30.0, 55.0], satisfactionScore: 9.5)!
        ]
        
        let regressor = await KNNRegressor(numNeighbors: 3)
        await regressor.fit(trainingData)
        
        let highActivityMetrics = [11000.0, 8.2, 1100.0, 65.0, 13.0, 8.5, 8500.0, 22.0, 59.0]
        let highPrediction = try await regressor.predictSatisfactionScore(highActivityMetrics)
        
        // Should be within the 8-9 range
        #expect(highPrediction > 7.5)
        #expect(highPrediction < 9.5)
        
        let lowActivityMetrics = [5500.0, 6.2, 550.0, 22.0, 8.5, 5.5, 4500.0, 11.0, 73.0]
        let lowPrediction = try await regressor.predictSatisfactionScore(lowActivityMetrics)
        
        // Should be within the 5-6 range
        #expect(lowPrediction > 4.5)
        #expect(lowPrediction < 6.5)
        
        #expect(highPrediction > lowPrediction)
        
        // Unfitted model should throw an error
        let unfittedRegressor = await KNNRegressor(numNeighbors: 3)
        #expect(throws: Error.self) {
            try unfittedRegressor.predictSatisfactionScore(highActivityMetrics)
        }
    }
    
    // weightedAverage() is a private function but we can implicitely test it through predictSatisfactionScore()
    @Test func testWeightedAverage() async throws {
        let trainingData: [SatisfactionEntry] = [
            SatisfactionEntry(from: [10000.0, 8.0, 1000.0, 60.0, 12.0, 8.0, 8000.0, 20.0, 60.0], satisfactionScore: 8.0)!,
            SatisfactionEntry(from: [5000.0, 6.0, 500.0, 20.0, 8.0, 5.0, 4000.0, 10.0, 75.0], satisfactionScore: 5.0)!,
            SatisfactionEntry(from: [15000.0, 9.0, 1500.0, 80.0, 15.0, 10.0, 11000.0, 30.0, 55.0], satisfactionScore: 9.0)!
        ]
        
        let regressor = await KNNRegressor(numNeighbors: 3)
        await regressor.fit(trainingData)
        
        let nearFirstPoint = [10050.0, 8.0, 1005.0, 60.0, 12.0, 8.0, 8050.0, 20.0, 60.0]
        let prediction = try await regressor.predictSatisfactionScore(nearFirstPoint)
        
        // Prediction should be heavily influenced by the nearest neighbor (8.0)
        // and should be closer to 8.0 than to the average of all three (7.33)
        #expect(abs(prediction - 8.0) < 0.5)
        #expect(abs(prediction - 7.33) > 0.3)
        
        // Additional verification: The prediction should be between min and max of neighbors
        #expect(prediction >= 5.0)
        #expect(prediction <= 9.0)
    }
}
