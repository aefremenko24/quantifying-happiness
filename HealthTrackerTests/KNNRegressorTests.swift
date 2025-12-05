//
//  KNNRegressorTests.swift
//  KNNRegressorTests
//
//  Created by Arthur Efremenko on 11/25/25.
//

import Testing
@testable import HealthTracker

struct KNNRegressorTests {
    let scaler: FeatureScaler
    
    init() {
        self.scaler = FeatureScaler()
    }
    
    @Test func testPredictSatisfactionScore() throws {
        let trainingData: [SatisfactionEntry] = [
            SatisfactionEntry(from: [10000.0, 8.0, 1000.0, 60.0, 12.0, 8.0, 8000.0, 20.0, 60.0], satisfactionScore: 8.0)!,
            SatisfactionEntry(from: [12000.0, 8.5, 1200.0, 70.0, 14.0, 9.0, 9000.0, 25.0, 58.0], satisfactionScore: 9.0)!,
            SatisfactionEntry(from: [5000.0, 6.0, 500.0, 20.0, 8.0, 5.0, 4000.0, 10.0, 75.0], satisfactionScore: 5.0)!,
            SatisfactionEntry(from: [6000.0, 6.5, 600.0, 25.0, 9.0, 6.0, 5000.0, 12.0, 72.0], satisfactionScore: 6.0)!,
            SatisfactionEntry(from: [15000.0, 9.0, 1500.0, 80.0, 15.0, 10.0, 11000.0, 30.0, 55.0], satisfactionScore: 9.5)!
        ]
        self.scaler.fit(trainingData.map({ $0.toList() }))
        
        let regressor = KNNRegressor(trainingData: trainingData, numNeighbors: 3)
        try regressor.fit(scaler: self.scaler)
        
        var highActivityMetrics = [11000.0, 8.2, 1100.0, 65.0, 13.0, 8.5, 8500.0, 22.0, 59.0]
        highActivityMetrics = try scaler.transform(highActivityMetrics)
        let highPrediction = try regressor.predictSatisfactionScore(highActivityMetrics)
        
        // Should be within the 8-9 range
        #expect(highPrediction > 7.5)
        #expect(highPrediction < 9.5)
        
        var lowActivityMetrics = [5500.0, 6.2, 550.0, 22.0, 8.5, 5.5, 4500.0, 11.0, 73.0]
        lowActivityMetrics = try scaler.transform(lowActivityMetrics)
        let lowPrediction = try regressor.predictSatisfactionScore(lowActivityMetrics)
        
        // Should be within the 5-6 range
        #expect(lowPrediction > 4.5)
        #expect(lowPrediction < 6.5)
        
        #expect(highPrediction > lowPrediction)
        
        // Unfitted model should throw an error
        let unfittedRegressor = KNNRegressor(trainingData: trainingData, numNeighbors: 3)
        #expect(throws: Error.self) {
            try unfittedRegressor.predictSatisfactionScore(highActivityMetrics)
        }
    }
    
    // weightedAverage() is a private function but we can implicitely test it through predictSatisfactionScore()
    @Test func testWeightedAverage() throws {
        let trainingData: [SatisfactionEntry] = [
            SatisfactionEntry(from: [10000.0, 8.0, 1000.0, 60.0, 12.0, 8.0, 8000.0, 20.0, 60.0], satisfactionScore: 8.0)!,
            SatisfactionEntry(from: [5000.0, 6.0, 500.0, 20.0, 8.0, 5.0, 4000.0, 10.0, 75.0], satisfactionScore: 5.0)!,
            SatisfactionEntry(from: [15000.0, 9.0, 1500.0, 80.0, 15.0, 10.0, 11000.0, 30.0, 55.0], satisfactionScore: 9.0)!
        ]
        self.scaler.fit(trainingData.map({ $0.toList() }))
        
        let regressor =  KNNRegressor(trainingData: trainingData, numNeighbors: 3)
        try regressor.fit(scaler: scaler)
        
        var nearFirstPoint = [10050.0, 8.0, 1005.0, 60.0, 12.0, 8.0, 8050.0, 20.0, 60.0]
        nearFirstPoint = try scaler.transform(nearFirstPoint)
        let prediction = try regressor.predictSatisfactionScore(nearFirstPoint)
        
        // Prediction should be heavily influenced by the nearest neighbor (8.0)
        // and should be closer to 8.0 than to the average of all three (7.33)
        #expect(abs(prediction - 8.0) < 0.5)
        #expect(abs(prediction - 7.33) > 0.3)
        
        // Additional verification: The prediction should be between min and max of neighbors
        #expect(prediction >= 5.0)
        #expect(prediction <= 9.0)
    }
}
