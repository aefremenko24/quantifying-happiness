//
//  FeatureScaler.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/26/25.
//

import Foundation

// Custom errors
private enum FeatureScalerErrors: Error {
    case valueError(String)
    case unfittedModelError(String)
}

// Normalizes data points
class FeatureScaler {
    private var mins: [Double] = []
    private var maxs: [Double] = []
    private var isFitted: Bool = false
    
    // Calculate means and standard deviations
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
    
    // Normalize each data point
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
    
    // Reverse normalization for each data point
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
