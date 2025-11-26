//
//  FeatureScalerTests.swift
//  HealthTrackerTests
//
//  Created by Arthur Efremenko on 11/26/25.
//

import Testing
@testable import HealthTracker

struct FeatureScalerTests {
    @Test func testFit() throws {
        let testData = [
            [10.0, 20.0, 30.0],
            [20.0, 40.0, 60.0],
            [30.0, 60.0, 90.0]
        ]
        
        let scaler = FeatureScaler()
        
        scaler.fit(testData)
        
        // Min values should transform to 0
        let transformedMin = try scaler.transform([10.0, 20.0, 30.0])
        #expect(abs(transformedMin[0] - 0.0) < 0.001)
        #expect(abs(transformedMin[1] - 0.0) < 0.001)
        #expect(abs(transformedMin[2] - 0.0) < 0.001)
        
        // Mid values should transform to 0.5
        let transformedMid = try scaler.transform([20.0, 40.0, 60.0])
        #expect(abs(transformedMid[0] - 0.5) < 0.001)
        #expect(abs(transformedMid[1] - 0.5) < 0.001)
        #expect(abs(transformedMid[2] - 0.5) < 0.001)
        
        // Max values should transform to 1
        let transformedMax = try scaler.transform([30.0, 60.0, 90.0])
        #expect(abs(transformedMax[0] - 1.0) < 0.001)
        #expect(abs(transformedMax[1] - 1.0) < 0.001)
        #expect(abs(transformedMax[2] - 1.0) < 0.001)
    }
    
    @Test func testTransform() throws {
        let testData = [
            [0.0, 0.0],
            [10.0, 20.0],
            [20.0, 40.0]
        ]
        
        let scaler = FeatureScaler()
        scaler.fit(testData)
        
        let transformed = try scaler.transform([15.0, 30.0])
        
        // Normalization formula: (x - min) / (max - min)
        // (15 - 0) / 20 = 0.75
        // (30 - 0) / 40 = 0.75
        #expect(abs(transformed[0] - 0.75) < 0.001)
        #expect(abs(transformed[1] - 0.75) < 0.001)
        
        // Edge case: min == max
        let constantData = [[5.0, 5.0], [5.0, 5.0], [5.0, 5.0]]
        let constantScaler = FeatureScaler()
        constantScaler.fit(constantData)
        let constantTransform = try constantScaler.transform([5.0, 5.0])
        
        #expect(constantTransform[0] == 0.0)
        #expect(constantTransform[1] == 0.0)
        
        // Error handling for unfitted scaler
        let unfittedScaler = FeatureScaler()
        #expect(throws: Error.self) {
            try unfittedScaler.transform([1.0, 2.0])
        }
        
        // Error handling for dimension mismatch
        #expect(throws: Error.self) {
            try scaler.transform([1.0, 2.0, 3.0])
        }
    }
    
    @Test func testInverseTransform() throws {
        let testData = [
            [0.0, 100.0],
            [50.0, 200.0],
            [100.0, 300.0]
        ]
        
        let scaler = FeatureScaler()
        scaler.fit(testData)
        
        let original = [75.0, 250.0]
        let normalized = try scaler.transform(original)
        let reconstructed = try scaler.inverseTransform(normalized)
        
        #expect(abs(reconstructed[0] - original[0]) < 0.001)
        #expect(abs(reconstructed[1] - original[1]) < 0.001)
        
        let normalizedZero = [0.0, 0.0]
        let reconstructedMin = try scaler.inverseTransform(normalizedZero)
        #expect(abs(reconstructedMin[0] - 0.0) < 0.001)
        #expect(abs(reconstructedMin[1] - 100.0) < 0.001)
        
        let normalizedOne = [1.0, 1.0]
        let reconstructedMax = try scaler.inverseTransform(normalizedOne)
        #expect(abs(reconstructedMax[0] - 100.0) < 0.001)
        #expect(abs(reconstructedMax[1] - 300.0) < 0.001)
        
        // Error handling for unfitted scaler
        let unfittedScaler = FeatureScaler()
        #expect(throws: Error.self) {
            try unfittedScaler.inverseTransform([0.5, 0.5])
        }
        
        // Error error handling for dimension mismatch
        #expect(throws: Error.self) {
            try scaler.inverseTransform([0.5]) // Wrong dimension
        }
    }
}
