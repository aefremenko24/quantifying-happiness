//
//  LocalSearchOptimizer.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

private enum LocalSearchOptimizerError: Error {
    case valueError(String)
}

class LocalSearchOptimizer {
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
        

        self.regressor.fit(self.data)
        
        //get ranges from past
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
    }
    
    private func clamp(_ params: [Double]) -> [Double] {
        guard params.count == minValues.count else { return params }
        
        var clamped: [Double] = []
        for i in 0..<params.count {
            let lo = minValues[i]
            let hi = maxValues[i]
            clamped.append(max(lo, min(hi, params[i])))
        }
        return clamped
    }
    
    
    //simulated annealing including random restarts
    //random restarts manually input which isn't very modular as per syllabus...
    func optimize(
        initialParams: SatisfactionEntry,
        maxIterations: Int,
        numRestarts: Int = 1
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        guard initialParams.userSatisfactionScore != nil else {
            throw LocalSearchOptimizerError.valueError("Initial parameters must include a satisfaction score.")
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