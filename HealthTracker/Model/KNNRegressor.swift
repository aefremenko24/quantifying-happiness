//
//  KNNRegressor.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

/// Custom errors
private enum KNNRegressorError: Error {
    case valueError(String)
    case fittingError(String)
    case unfittedModelError(String)
}

/// Calculate the euclidean distance between two points in n dimensions.
///
/// The euclidian distance between some points p1 and p2 in n dimensions is given by:
///     `\sqrt{\sum_{i=1}^{n} (p1_i - p2_i)^2}`
///
/// - Parameters:
///   - point1: An ordered list of coordinates for each dimension of the first point.
///   - point2: An ordered list of coordinates for each dimension of the second point.
/// - Returns: Euclidian distance between the two points.
/// - Throws: `KNNRegressorError.valueError` if the given points have different dimensions.
private func calculateEuclideanDistance(from point1: [Double], to point2: [Double]) throws -> Double {
    guard point1.count == point2.count else {
        throw KNNRegressorError.valueError("Feature dimensions must match")
    }
    
    let squaredDiffs = zip(point1, point2).map { pow($0 - $1, 2) }
    return sqrt(squaredDiffs.reduce(0, +))
}

/// Allows us to make predictions for the satisfaction score for unseen metrics combinations
class KNNRegressor {
    private var trainingData: [SatisfactionEntry] = []
    private let numNeighbors: Int
    private var isFitted: Bool = false
    
    init(trainingData: [SatisfactionEntry], numNeighbors: Int) {
        self.trainingData = trainingData
        self.numNeighbors = numNeighbors
    }
    
    /// Given a feature scaler, normalize all data points in the training data.
    ///
    /// - Parameters:
    ///   - scaler: A fitted feature scaler that is able to perform normalization.
    /// - Throws:`KNNRegressorError.fittingError` if the scaler failed to transform the data.
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
    
    /// Get the predicted satisfaction score for a given set of metrics.
    ///
    /// The value is predicted using a k-Nearest-Neighbors algorithm.
    /// It works by finding the 'k' closest data points in the training data and assigning
    /// the given point the weighted average of the satisfaction scores of those neighbors.
    ///
    /// - Parameters:
    ///   - features: Data point as an ordered list of its coordinates.
    /// - Returns: Predicted satisfaction score.
    /// - Throws:
    ///   - `KNNRegressorError.unfittedModelError` if there is no training data or the regressor has not been fitted.
    ///   - Errors from `calculateEuclideanDistance()` if distance calculations fail.
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
    
    /// Calculate the weighted average of the satisfaction score of 'k' given neighbors.
    ///
    /// The weight of each neighbor's contribution is inversely proportional to its distance.
    /// A small epsilon value is added to every distance to avoid division by zero.
    ///
    /// - Parameters:
    ///   - neighbors: List of neighboring points, each being a tuple of two values:
    ///     - `distance`: Euclidean distance to the new data point.
    ///     - `satisfaction`: True satisfaction score of the neighbor.
    /// - Returns: Weighted average of the satisfaction scores of the given neighbors.
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
