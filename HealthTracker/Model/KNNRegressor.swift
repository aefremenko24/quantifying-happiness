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

// Allows us to make predictions for the satisfaction score for unseen metrics combinations
class KNNRegressor {
    private var trainingData: [SatisfactionEntry] = []
    private let numNeighbors: Int
    private var isFitted: Bool = false
    
    init(trainingData: [SatisfactionEntry], numNeighbors: Int) {
        self.trainingData = trainingData
        self.numNeighbors = numNeighbors
    }
    
    func fit(scaler: FeatureScaler) throws {
        do {
            var transformedTrainingData: [SatisfactionEntry] = []
            for entry in trainingData {
                let transformedEntry = try scaler.transform(entry.toList())
                transformedTrainingData.append(
                    SatisfactionEntry(from: transformedEntry, satisfactionScore: entry.userSatisfactionScore)!
                )
            }
            self.trainingData = transformedTrainingData
            self.isFitted = true
        } catch {
            throw KNNRegressorError.fittingError("Failed to fit KNN Regressor: \(error)")
        }
    }
    
    // Get satisfaction score for a given set of metrics
    func predictSatisfactionScore(_ features: [Double]) throws -> Double {
        guard !trainingData.isEmpty else {
            throw KNNRegressorError.unfittedModelError("Model cannot run without training data")
        }
        
        guard isFitted else {
            throw KNNRegressorError.unfittedModelError("Regressor must be fitted before making predicitons. Call fit() first.")
        }
        
        // Calculate distances to all training points
        var distances: [(distance: Double, satisfaction: Double)] = []
        
        for dataPoint in trainingData {
            if dataPoint.userSatisfactionScore != nil {
                let distance = try calculateEuclideanDistance(from: features, to: dataPoint.toList())
                distances.append((distance, dataPoint.userSatisfactionScore!))
            }
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
