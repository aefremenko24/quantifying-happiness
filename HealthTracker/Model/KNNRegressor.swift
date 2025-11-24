//
//  KNNRegressor.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

// Custom errors
private enum KNNRegressorError: Error {
    case valueError(String)
    case unfittedModelError(String)
}

// Euclidean distance between two points in n dimensions
private func calculateEuclideanDistance(from point1: [Double], to point2: [Double]) throws -> Double {
    guard point1.count == point2.count else {
        throw KNNRegressorError.valueError("Feature dimensions must match")
    }
    
    let squaredDiffs = zip(point1, point2).map { pow($0 - $1, 2) }
    return sqrt(squaredDiffs.reduce(0, +))
}

// Standardizes the data points
private class FeatureScaler {
    private var means: [Double] = []
    private var stdDevs: [Double] = []
    
    // Calculate means and standard deviations
    func fit(_ data: [[Double]]) {
        guard !data.isEmpty else {
            return
        }
        
        let numFeatures = data[0].count
        means = Array(repeating: 0.0, count: numFeatures)
        stdDevs = Array(repeating: 0.0, count: numFeatures)
        
        for featureIdx in 0..<numFeatures {
            let featureValues = data.map { $0[featureIdx] }
            
            means[featureIdx] = featureValues.reduce(0, +) / Double(featureValues.count)
            
            let squaredDiffs = featureValues.map { pow($0 - means[featureIdx], 2) }
            stdDevs[featureIdx] = sqrt(squaredDiffs.reduce(0, +) / Double(featureValues.count))
        }
    }
    
    // Apply the standardization formula to each data point
    func transform(_ features: [Double]) -> [Double] {
        return zip(features, zip(means, stdDevs)).map { feature, stats in
            let (mean, std) = stats
            return std > 0 ? (feature - mean) / std : 0
        }
    }
}

// Allows us to make predictions for the satisfaction score for unseen metrics combinations
class KNNRegressor {
    private var trainingData: [SatisfactionEntry] = []
    private let numNeighbors: Int
    private let scaler: FeatureScaler
    
    init(trainingData: [SatisfactionEntry] = [], numNeighbors: Int = 5) {
        self.trainingData = trainingData
        self.numNeighbors = numNeighbors
        self.scaler = FeatureScaler()
    }
    
    func fit(_ data: [SatisfactionEntry]) {
        self.trainingData = data
        
        let features = data.map { $0.toList() }
        scaler.fit(features)
    }
    
    // Get satisfaction score for a given set of metrics
    func predictSatisfactionScore(_ features: [Double]) throws -> Double {
        guard !trainingData.isEmpty else {
            throw KNNRegressorError.unfittedModelError("Model must be fitted before prediction")
        }
        
        // Scale the query features
        let scaledQuery = scaler.transform(features)
        
        // Calculate distances to all training points
        var distances: [(distance: Double, satisfaction: Double)] = []
        
        for dataPoint in trainingData {
            let scaledFeatures = scaler.transform(dataPoint.toList())
            let distance = try calculateEuclideanDistance(from: scaledQuery, to: scaledFeatures)
            distances.append((distance, dataPoint.userSatisfactionScore))
        }
        
        distances.sort { $0.distance < $1.distance }
        let kNearest = Array(distances.prefix(numNeighbors))
        
        return weightedAverage(kNearest)
    }
    
    // Inverse distance weighting with epsilon to avoid division by zero
    private func weightedAverage(_ neighbors: [(distance: Double, satisfaction: Double)]) -> Double {
        let epsilon = 1e-8
        
        var weightedSum = 0.0
        var totalWeight = 0.0
        
        for neighbor in neighbors {
            let weight = 1.0 / (neighbor.distance + epsilon)
            weightedSum += weight * neighbor.satisfaction
            totalWeight += weight
        }
        
        return weightedSum / totalWeight
    }
}
