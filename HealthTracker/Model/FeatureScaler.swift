//
//  FeatureScaler.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/26/25.
//

import Foundation

/// Custom errors
private enum FeatureScalerErrors: Error {
    case valueError(String)
    case unfittedModelError(String)
}

/// Normalizes data points for use with KNN Regressor and Simulated Annealing
class FeatureScaler {
    private var mins: [Double] = []
    private var maxs: [Double] = []
    private var isFitted: Bool = false
    
    /// Extract essential parameters from the given set of data.
    ///
    /// Before the feature scaler can apply normalization to arbitrary data points,
    /// it needs to calculate and store the minimum and the maximum values of
    /// the whole training data set.git
    ///
    /// - Parameters:
    ///   - data: A list of training data points, each containing the same number of health metrics.
    func fit(_ data: [[Double]]) {
        guard !data.isEmpty else {
            return
        }
        
        let numFeatures = data[0].count
        mins = Array(repeating: Double.infinity, count: numFeatures)
        maxs = Array(repeating: -Double.infinity, count: numFeatures)
        
        for featureIdx in 0..<numFeatures {
            let featureValues = data.map { $0[featureIdx] }
            
            mins[featureIdx] = featureValues.min() ?? 0
            maxs[featureIdx] = featureValues.max() ?? 1
        }
        
        isFitted = true
    }
    
    /// Normalize the given data point.
    ///
    /// - Parameters:
    ///   - features: Data point as a list of health metrics.
    ///
    /// - Returns: Data point after normalization with respect to the fitted data.
    ///
    /// - Throws:
    ///   - `FeatureScalerErrors.unfittedModelError` if the scaler has not been fit to any training data.
    ///   - `FeatureScalerErrors.valueError` if the dimension of the data point does not match the dimension of the previously fit data.
    func transform(_ features: [Double]) throws -> [Double] {
        guard isFitted else {
            throw FeatureScalerErrors.unfittedModelError("Scaler must be fitted before inverse transformation. Call fit() first.")
        }
        
        guard features.count == mins.count && features.count == maxs.count else {
            throw FeatureScalerErrors.valueError("Feature dimension mismatch: expected \(mins.count), \(maxs.count), got \(features.count)")
        }
        
        return zip(features, zip(mins, maxs)).map { feature, bounds in
            let (min, max) = bounds
            return max > min ? (feature - min) / (max - min) : 0
        }
    }
    
    /// Reverse normalization for the given data point.
    ///
    /// - Parameters:
    ///   - features: Data point as a list of health metrics.
    ///
    /// - Returns: Data point after reverse normalization with respect to the fitted data.
    ///
    /// - Throws:
    ///   - `FeatureScalerErrors.unfittedModelError` if the scaler has not been fit to any training data.
    ///   - `FeatureScalerErrors.valueError` if the dimension of the data point does not match the dimension of the previously fit data.
    func inverseTransform(_ scaledFeatures: [Double]) throws -> [Double] {
        guard isFitted else {
            throw FeatureScalerErrors.unfittedModelError("Scaler must be fitted before inverse transformation. Call fit() first.")
        }
        
        guard scaledFeatures.count == mins.count && scaledFeatures.count == maxs.count else {
            throw FeatureScalerErrors.valueError("Feature dimension mismatch: expected \(mins.count), \(maxs.count), got \(scaledFeatures.count)")
        }
        
        return zip(scaledFeatures, zip(mins, maxs)).map { scaledFeature, bounds in
            let (min, max) = bounds
            return scaledFeature * (max - min) + min
        }
    }
}
