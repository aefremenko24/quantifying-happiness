//
//  SimulatedAnnealingOptimizer.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

/// Custom errors
private enum SimulatedAnnealingOptimizerError: Error {
    case valueError(String)
}

/// Simulated Annealing model used to optimize health metrics.
class SimulatedAnnealingOptimizer {
    private let data: [SatisfactionEntry]
    private let regressor: KNNRegressor
    
    private let initialTemperature: Double
    private let coolingRate: Double
    private let stepSize: Double
    
    //clamping
    private let minValues: [Double]
    private let maxValues: [Double]
    
    init(data: [SatisfactionEntry],
         initialTemperature: Double = 100.0,
         coolingRate: Double = 0.95,
         stepSize: Double = 0.5
    ) {
        self.data = data
        self.initialTemperature = initialTemperature
        self.coolingRate = coolingRate
        self.stepSize = stepSize
        self.regressor = KNNRegressor()
        
        self.scaler = FeatureScaler()
        self.scaler.fit(data.map { $0.toList() })
        
        self.regressor = KNNRegressor(trainingData: data, numNeighbors: 5)
        do {
            try self.regressor.fit(scaler: scaler)
        } catch {
            print("Error when fitting the KNN regressor: \(error)")
        }
    }
    
    /// Find an optimal combination of health metrics using simulated annealing.
    ///
    /// The algorithm works with parameters normalized using the feature scaler and returns
    /// the solution transformed back to the original scale.
    ///
    /// - Parameters:
    ///   - initialParams: Starting point for optimization containing the initial metrics and a satisfaction score.
    ///   - maxIterations: Maximum number of optimization iterations.
    /// - Returns: A tuple containing:
    ///   - `value`: The best `SatisfactionEntry` found during optimization (in original scale).
    ///   - `history`: A list of all accepted `SatisfactionEntry` states during the optimization.
    /// - Throws:
    ///   - `SimulatedAnnealingOptimizerError.valueError` if the initial parameters are missing a satisfaction score.
    ///   - Errors from `scaler.transform()` if feature transformation fails.
    ///   - Errors from `regressor.predictSatisfactionScore()` if prediction fails.
    ///   - Errors from `scaler.inverseTransform()` if inverse transformation of the final result fails.
    func optimize(
        initialParams: SatisfactionEntry,
        maxIterations: Int,
        numRestarts: Int = 1
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        guard initialParams.userSatisfactionScore != nil else {
            throw SimulatedAnnealingOptimizerError.valueError("Satisfaction score must be present in the initial parameters")
        }
        
        let validEntries = data.filter { $0.userSatisfactionScore != nil }
        let restarts = max(numRestarts, 1)
        
        var globalBest: SatisfactionEntry?
        var globalBestValue = -Double.greatestFiniteMagnitude
        var globalHistory: [SatisfactionEntry] = []
        
        for restartIndex in 0..<restarts {
            
            let startEntry: SatisfactionEntry =
                restartIndex == 0 ? initialParams :
                (validEntries.randomElement() ?? initialParams)
            
            let (bestForRestart, historyForRestart) = try runSingleAnnealing(
                from: startEntry,
                maxIterations: maxIterations,
                restartIndex: restartIndex
            )
            
            globalHistory.append(contentsOf: historyForRestart)
            
            if let score = bestForRestart.userSatisfactionScore,
               score > globalBestValue {
                globalBestValue = score
                globalBest = bestForRestart
            }
        }
        
        guard let finalBest = globalBest else {
            throw LocalSearchOptimizerError.valueError("Optimizer failed to find a valid result.")
        }
        
        return (finalBest, globalHistory)
    }
    
    
    //simulated annealing using clamp
    private func runSingleAnnealing(
        from startParams: SatisfactionEntry,
        maxIterations: Int,
        restartIndex: Int
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        var currentParams = startParams
        var currentValue = currentParams.userSatisfactionScore!
        var bestParams = currentParams
        var bestValue = currentValue
        var history: [SatisfactionEntry] = [currentParams]
        
        var temperature = initialTemperature
        
        for iteration in 0..<maxIterations {
            var candidate = currentParams.toList()
            
            let dim = Int.random(in: 0..<candidate.count)
            candidate[dim] += Double.random(in: -stepSize...stepSize)
            
            //clamp to realistic human ranges
            candidate = clamp(candidate)
            
            let candidateValue = try regressor.predictSatisfactionScore(candidate)
            let delta = candidateValue - currentValue
            
            let acceptanceProbability = delta > 0
                ? 1.0
                : exp(delta / temperature)
            
            if Double.random(in: 0...1) < acceptanceProbability {
                if let newEntry = SatisfactionEntry(from: candidate, satisfactionScore: candidateValue) {
                    currentParams = newEntry
                    currentValue = candidateValue
                    history.append(newEntry)
                    
                    if currentValue > bestValue {
                        bestValue = currentValue
                        bestParams = newEntry
                    }
                }
            }
            
            temperature *= coolingRate
        }
        
        return (bestParams, history)
    }
}
