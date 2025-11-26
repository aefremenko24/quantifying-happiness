//
//  LocalSearchOptimizer.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

// Custom errors
private enum LocalSearchOptimizerError: Error {
    case valueError(String)
}

class LocalSearchOptimizer {
    private let data: [SatisfactionEntry]
    private let regressor: KNNRegressor
    
    private let initialTemperature: Double
    private let coolingRate: Double
    private let stepSize: Double
    
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

        if data.isEmpty {
            self.minValues = []
            self.maxValues = []
        } else {
            let featureLists = data.map { $0.toList() }
            let featureCount = featureLists[0].count
            
            var mins = Array(repeating: Double.greatestFiniteMagnitude, count: featureCount)
            var maxs = Array(repeating: -Double.greatestFiniteMagnitude, count: featureCount)
            
            for features in featureLists {
                for i in 0..<featureCount {
                    let v = features[i]
                    if v < mins[i] { mins[i] = v }
                    if v > maxs[i] { maxs[i] = v }
                }
            }
            
            self.minValues = mins
            self.maxValues = maxs
        }
        
        self.regressor.fit(self.data)
    }
    
    func optimize(
        initialParams: SatisfactionEntry,
        maxIterations: Int
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        guard initialParams.userSatisfactionScore != nil else {
            throw LocalSearchOptimizerError.valueError("Satisfaction score must be present in the initial parameters")
        }
        
        var currentParams = initialParams
        var currentValue = currentParams.userSatisfactionScore!
        var bestParams = currentParams
        var bestValue = currentValue
        var history: [SatisfactionEntry] = [currentParams]
        
        var temperature = initialTemperature
        
        print("Starting simulated annealing from satisfaction value: \(String(format: "%.4f", currentValue))")
        
        for iteration in 0..<maxIterations {
            var candidateParamsList = currentParams.toList()
            let dimToChange = Int.random(in: 0..<candidateParamsList.count)
            candidateParamsList[dimToChange] += Double.random(in: -stepSize...stepSize)
            
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
            
            print("Iteration \(iteration): Current = \(String(format: "%.4f", currentValue)), Best = \(String(format: "%.4f", bestValue)), Temp = \(String(format: "%.2f", temperature))")
        }
        
        return (bestParams, history)
    }

    //ensures all generated health metrics are within realistic range
    //prevents the model from having the user sleep for like 12 hours a day 
    private func clamp(_ params: [Double]) -> [Double] {
        guard params.count == minValues.count, !minValues.isEmpty else {
            return params
        }
        
        var clamped: [Double] = []
        clamped.reserveCapacity(params.count)
        
        for i in 0..<params.count {
            let value = params[i]
            let lo = minValues[i]
            let hi = maxValues[i]
            clamped.append(max(lo, min(hi, value)))
        }
        
        return clamped
    }

    //same logic as optimize() but optimizing the KNN prediction value as opposed to user satisfaction score
    func optimizePrediction(
        initialParams: SatisfactionEntry,
        maxIterations: Int
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        var currentParams = initialParams
        var currentValue = try regressor.predictSatisfactionScore(currentParams.toList())
        var bestParams = currentParams
        var bestValue = currentValue
        var history: [SatisfactionEntry] = [currentParams]
        
        var temperature = initialTemperature
        
        print("Starting simulated annealing from predicted satisfaction value: \(String(format: "%.4f", currentValue))")
        
        for iteration in 0..<maxIterations {
            var candidateParamsList = currentParams.toList()
            
            //perturb a single dimension
            let dimToChange = Int.random(in: 0..<candidateParamsList.count)
            candidateParamsList[dimToChange] += Double.random(in: -stepSize...stepSize)
            
            // Keep candidate within valid bounds
            candidateParamsList = clamp(candidateParamsList)
            
            //predicted value from regressor
            let candidateValue = try regressor.predictSatisfactionScore(candidateParamsList)
            
            let delta = candidateValue - currentValue
            
            let safeTemperature = max(temperature, 1e-3)
            let acceptanceProbability = delta > 0 ? 1.0 : exp(delta / safeTemperature)
            
            if Double.random(in: 0...1) < acceptanceProbability {
                if let newEntry = SatisfactionEntry(from: candidateParamsList, satisfactionScore: candidateValue) {
                    currentParams = newEntry
                    currentValue = candidateValue
                    history.append(currentParams)
                    
                    if currentValue > bestValue {
                        bestValue = currentValue
                        bestParams = currentParams
                    }
                }
            }
            
            temperature = max(temperature * coolingRate, 1e-3)
            
            print("Iteration \(iteration): Current = \(String(format: "%.4f", currentValue)), Best = \(String(format: "%.4f", bestValue)), Temp = \(String(format: "%.3f", temperature))")
        }
        
        return (bestParams, history)
    }
}