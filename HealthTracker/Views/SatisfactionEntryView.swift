//
//  SatisfactionEntryView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI
import HealthKit

@MainActor
struct SatisfactionEntryView: View {
    let date: Date
    @Binding var satisfactionEntry: SatisfactionEntry?
    @State var healthStore: HKHealthStore = HKHealthStore()
    @State var metrics: HealthMetrics?
    @State var currentSatisfactionScore: Int?
    
    let updateEntryModel: (SatisfactionEntry) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                VStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .foregroundStyle(.primary)
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                    Spacer()
                }
            }
            
            VStack(alignment: .center) {
                if (date > Date()) {
                    Text("No data available for this date yet, come back later")
                }
                else if (metrics == nil) {
                    Text("Fetching health data...")
                } else {
                    Text("How happy were you on \(date.formatted(Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated)))?")
                    SatisfactionScoreEntryView(satisfactionScore: $currentSatisfactionScore)
                        .padding(.bottom, 10)
                    
                    Text("Steps today: \(Int(metrics!.stepsToday))")
                    Text("Time in bed last night: \(Int(metrics!.timeInBedLastNight)) minutes")
                    Text("Active energy: \(String(format: "%.2f", metrics!.activeEnergyToday)) kcal")
                    Text("Exercise time: \(Int(metrics!.exerciseMinutesToday)) minutes")
                    Text("Stand hours: \(Int(metrics!.standHoursToday)) hours")
                    Text("Daylight time: \(Int(metrics!.daylightTimeToday)) minutes")
                    Text("Distance: \(String(format: "%.2f", metrics!.distanceWalkingToday)) meters")
                    Text("Flights climbed: \(Int(metrics!.flightsClimbedToday))")
                    Text("Resting HR: \(Int(metrics!.restingHeartRateToday)) bpm")
                    
                    Text("\nActivity Rings:")
                        .bold()
                    Text("Move: \(Int(metrics!.moveRingProgress * 100))%")
                    Text("Exercise: \(Int(metrics!.exerciseRingProgress * 100))%")
                    Text("Stand: \(Int(metrics!.standRingProgress * 100))%")
                }
            }
        }
        .onAppear {
            let metricsManager = HealthMetricsManager(healthStore: healthStore)
            
            Task {
                do {
                    try await metricsManager.requestAuthorization()
                } catch {
                    print("Authorization failed: \(error)")
                }
            }
            
            Task {
                do {
                    let endOfDay = endOfDay(from: date)
                    let queryDate = Date() < endOfDay ? Date() : endOfDay
                    metrics = try await metricsManager.fetchAllMetrics(for: queryDate)
                } catch {
                    print("Error fetching metrics: \(error)")
                }
            }
        }
        .onChange(of: currentSatisfactionScore) {
            updateSatisfactionEntry()
        }
        .onChange(of: metrics) {
            updateSatisfactionEntry()
        }
    }
    
    private func updateSatisfactionEntry() {
        if metrics != nil && satisfactionEntry != nil {
            let newEntry = SatisfactionEntry(from: metrics!, date: date.startOfDay, satisfactionScore: Double(currentSatisfactionScore!))
            satisfactionEntry = newEntry
            updateEntryModel(newEntry)
        }
    }
    
    private func endOfDay(from date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }
}

#Preview {
    @Previewable @State var satisfactionEntry: SatisfactionEntry? = SatisfactionEntry(day: Date(), score: nil)
    SatisfactionEntryView(date: Date(), satisfactionEntry: $satisfactionEntry, updateEntryModel: {_ in })
}
