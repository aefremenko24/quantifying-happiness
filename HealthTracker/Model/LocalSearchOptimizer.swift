//
//  LocalSearchOptimizer.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 11/24/25.
//

import Foundation

class LocalSearchOptimizer {
    private let data: [SatisfactionEntry]
    private let regressor: KNNRegressor
    
    private let initialTemperature: Double
    private let coolingRate: Double
    private let stepSize: Double
    
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
    }
    
    func optimize(
        initialParams: SatisfactionEntry,
        maxIterations: Int
    ) throws -> (value: SatisfactionEntry, history: [SatisfactionEntry]) {
        
        var currentParams = initialParams
        var currentValue = currentParams.userSatisfactionScore
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
                currentParams = try SatisfactionEntry(fromList: candidateParamsList, satisfactionScore: candidateValue)
                currentValue = candidateValue
                
                history.append(currentParams)
                
                if currentValue > bestValue {
                    bestValue = currentValue
                    bestParams = currentParams
                }
            }
            
            temperature *= coolingRate
            
            if iteration % 100 == 0 {
                print("Iteration \(iteration): Current = \(String(format: "%.4f", currentValue)), Best = \(String(format: "%.4f", bestValue)), Temp = \(String(format: "%.2f", temperature))")
            }
        }
        
        return (bestParams, history)
    }
}
