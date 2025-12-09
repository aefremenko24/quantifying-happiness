//
//  SatisfactionEntryView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI
import HealthKit


/// A detail view for reviewing health metrics and recording a satisfaction
/// score for a specific date.
///
/// 'SatisfactionEntryView' fetches HealthKit data for the given 'date'
/// and displays a summary of daily metrics, and lets the user input how 
/// happy they were on that day using 'SatisfactionScoreEntryView'.
///
/// When health metrics or the satisfaction score change, the 
/// 'satisfactionEntry' is updated and 'updateEntryModel' is called so
/// the parent view can persist or refresh its data.
///
/// If no health data is available for the date the view displays an 
/// appropriate message instead of metrics.
@MainActor
struct SatisfactionEntryView: View {
    let date: Date
    @Binding var satisfactionEntry: SatisfactionEntry?
    @State var healthStore: HKHealthStore = HKHealthStore()
    @State var metrics: HealthMetrics?
    @State var currentSatisfactionScore: Int?
    @State var displayError: Bool = false
    
    let updateEntryModel: () -> Void
    
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
                if ((date.startOfDay >= Date().startOfDay) || displayError) {
                    Text("No data available for this date, come back later")
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
            if (date.startOfDay < Date().startOfDay) {
                let metricsManager = HealthMetricsManager(healthStore: healthStore)
                
                Task {
                    do {
                        try await metricsManager.requestAuthorization()
                    } catch {
                        print("Authorization failed: \(error)")
                        displayError = true
                    }
                }
                
                Task {
                    do {
                        let endOfDay = endOfDay(from: date)
                        let queryDate = Date() < endOfDay ? Date() : endOfDay
                        metrics = try await metricsManager.fetchAllMetrics(for: queryDate)
                    } catch {
                        print("Error fetching metrics: \(error)")
                        displayError = true
                    }
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

    /// Synchronizes the bound 'satisfactionEntry' with the latest
    /// health metrics and satisfaction score. This method is triggered 
    /// whenever 'metrics' or 'currentSatisfactionScore' changes.
    ///
    /// If 'satisfactionEntry' isn't 'nil', then this method will 
    /// update its health-related fields using 'metrics', if available,
    /// update its 'userSatisfactionScore' using 'currentSatisfactionScore', if available,
    /// call 'updateEntryModel()' so the parent can persist or refresh.
    private func updateSatisfactionEntry() {
        if satisfactionEntry != nil {
            if metrics != nil {
                satisfactionEntry!.updateHealthMetrics(metrics!)
            }
            if currentSatisfactionScore != nil {
                satisfactionEntry!.userSatisfactionScore = Double(currentSatisfactionScore!)
            }
            updateEntryModel()
        }
    }

    /// Computes the end of the day timestamp (23:59:59) for a given date.
    ///
    /// This is used to limit HealthKit queries to the end of the selected day.
    ///
    /// - Parameters:
    ///   - date: The date whose end-of-day boundary is requested.
    /// - Returns:
    ///   - 'date': A date representing 23:59:59 on the same calendar day.
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
    SatisfactionEntryView(date: Date(), satisfactionEntry: $satisfactionEntry, updateEntryModel: {})
}
