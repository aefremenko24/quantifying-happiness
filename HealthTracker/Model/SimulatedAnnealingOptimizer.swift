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
    private let scaler: FeatureScaler
    
    private let initialTemperature: Double
    private let coolingRate: Double
    private let stepSize: Double
    
    init(data: [SatisfactionEntry],
         initialTemperature: Double = 100.0,
         coolingRate: Double = 0.95,
         stepSize: Double = 0.05
    ) {
        self.data = data
        self.initialTemperature = initialTemperature
        self.coolingRate = coolingRate
        self.stepSize = stepSize
        
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
        maxIterations: Int
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        guard initialParams.userSatisfactionScore != nil else {
            throw SimulatedAnnealingOptimizerError.valueError("Satisfaction score must be present in the initial parameters")
        }
        
        let transformedParams = try scaler.transform(initialParams.toList())
        var currentParams = SatisfactionEntry(from: transformedParams, satisfactionScore: initialParams.userSatisfactionScore!)!
        var currentValue = currentParams.userSatisfactionScore!
        var bestParams = currentParams
        var bestValue = currentValue
        var history: [SatisfactionEntry] = [currentParams]
        var temperature = initialTemperature
        
        print("Starting simulated annealing with step \(stepSize) from parameters \(currentParams.toList())\n"
              + "with satisfaction value: \(String(format: "%.4f", currentValue))\n")
        
        for iteration in 0..<maxIterations {
            print("Iteration \(iteration):\n"
                  + "Current = \(String(format: "%.4f", currentValue)) for \(currentParams.toList()),\n"
                  + "Best = \(String(format: "%.4f", bestValue)) for \(bestParams.toList()),\n"
                  + "Temp = \(String(format: "%.2f", temperature))\n")
            
            var candidateParamsList = currentParams.toList()

            let dimToChange = Int.random(in: 0..<candidateParamsList.count)
            let randomStep = Double.random(in: -stepSize...stepSize)
            
            candidateParamsList[dimToChange] += randomStep
                
            let candidateValue = try self.regressor.predictSatisfactionScore(candidateParamsList)
            
            let delta = candidateValue - currentValue
            let acceptanceProbability = delta > 0 ? 1.0 : exp(delta / temperature)
            
            if Double.random(in: 0...1) < acceptanceProbability {
                currentParams = SatisfactionEntry(from: candidateParamsList, satisfactionScore: candidateValue) ?? currentParams
                currentValue = candidateValue
                
                history.append(currentParams)
                
                if currentValue > bestValue {
                    bestValue = currentValue
                    bestParams = currentParams
                }
            }
            
            temperature *= coolingRate
        }
        
        let finalBestParams = SatisfactionEntry(from: try scaler.inverseTransform(bestParams.toList()), satisfactionScore: bestValue) ?? bestParams
        return (finalBestParams, history)
    }
}
