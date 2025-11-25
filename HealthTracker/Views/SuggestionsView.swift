//
//  SuggestionsView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Environment(\.modelContext) private var context
    
    var currentSatisfactionEntry: SatisfactionEntry
    @State var suggestedSatisfactionEntry: SatisfactionEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if suggestedSatisfactionEntry == nil {
                Text("Loading suggestions...")
            } else {
                let metricNames = SatisfactionEntry.metricNamesList()
                let currentMetricValues: [Double] = currentSatisfactionEntry.toList()
                let suggestedMetricValues: [Double] = suggestedSatisfactionEntry!.toList()
                ForEach(Array(metricNames.enumerated()), id: \.offset) { index, metricName in
                    let metricDiff: Int = Int(suggestedMetricValues[index] - currentMetricValues[index])
                    let color: Color = metricDiff < 0 ? .red : metricDiff == 0 ? .primary : .green
                    HStack {
                        Text(metricName)
                            .font(.headline)
                        Spacer()
                        Text("\(abs(metricDiff))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(color)
                        
                        if metricDiff == 0 {
                            Text("—")
                                .foregroundStyle(color)
                        } else {
                            Image(systemName: metricDiff < 0 ? "chevron.down" : "chevron.up")
                                .foregroundStyle(color)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear() {
            Task {
                await loadSuggestions()
            }
        }
    }
    
    func loadSuggestions() async {
        let descriptor = FetchDescriptor<SatisfactionEntry>()
        let fetchedModels: [SatisfactionEntry]
        do {
            fetchedModels = try context.fetch(descriptor)
        } catch {
            print("Could not fetch SatisfactionEntries: \(error)")
            return
        }
        let optimizer = LocalSearchOptimizer(data: fetchedModels)
        do {
            let optimizerOutput = try optimizer.optimize(initialParams: currentSatisfactionEntry, maxIterations: 50)
            self.suggestedSatisfactionEntry = optimizerOutput.value
        } catch {
            print("Optimization failed: \(error)")
            return
        }
    }
}

#Preview {
    var currentSatisfactionEntry = SatisfactionEntry(from: [10298, 338, 621.67, 80, 18, 125, 7552.17, 7, 71], satisfactionScore: 10) ?? SatisfactionEntry(day: Date(), score: 10)
    var suggestedSatisfactionEntry = SatisfactionEntry(from: [13902, 434, 547.22, 21, 16, 237, 10293.95, 7, 60], satisfactionScore: 5) ?? SatisfactionEntry(day: Date(), score: 10)
    
    SuggestionsView(currentSatisfactionEntry: currentSatisfactionEntry, suggestedSatisfactionEntry: suggestedSatisfactionEntry)
}
