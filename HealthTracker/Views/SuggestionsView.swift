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
                    let metricDiff: Double = suggestedMetricValues[index] - currentMetricValues[index]
                    let color: Color = metricDiff < 0 ? .red : .green
                    HStack {
                        Text(metricName)
                            .font(.headline)
                        Spacer()
                        Image(systemName: metricDiff < 0 ? "chevron.down" : "chevron.up")
                            .foregroundStyle(color)
                        Text("\(abs(metricDiff))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(color)
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
    var currentSatisfactionEntry = SatisfactionEntry(fromList: [1, 2, 3, 4, 5, 6, 7, 8, 9], satisfactionScore: 10) ?? SatisfactionEntry(day: Date(), score: 10)
    var suggestedSatisfactionEntry = SatisfactionEntry(fromList: [9, 8, 7, 6, 5, 4, 3, 2, 1], satisfactionScore: 5) ?? SatisfactionEntry(day: Date(), score: 10)
    
    SuggestionsView(currentSatisfactionEntry: currentSatisfactionEntry, suggestedSatisfactionEntry: suggestedSatisfactionEntry)
}
