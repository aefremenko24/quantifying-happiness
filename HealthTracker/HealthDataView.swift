//
//  HealthDataView.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI
import HealthKit

@MainActor
struct HealthDataView: View {
    @State var healthStore: HKHealthStore = HKHealthStore()
    @State var metrics: HealthMetrics?
    
    var body: some View {
        VStack(alignment: .center) {
            if (metrics == nil) {
                Text("Fetching health data...")
            } else {
                Text("Steps today: \(Int(metrics!.stepsToday))")
                Text("Time in bed last night: \(Int(metrics!.timeInBedLastNight)) minutes")
                Text("Active energy: \(String(format: "%.2f", metrics!.activeEnergyToday)) kcal")
                Text("Exercise time: \(Int(metrics!.exerciseMinutesToday)) minutes")
                Text("Stand hours: \(Int(metrics!.standHoursToday)) hours")
                Text("Daylight time: \(Int(metrics!.daylightTimeToday)) minutes")
                Text("Distance: \(String(format: "%.2f", metrics!.distanceWalkingToday)) meters")
                Text("Flights climbed: \(Int(metrics!.flightsClimbedToday))")
                Text("Resting HR: \(Int(metrics!.restingHeartRateToday ?? 0)) bpm")
                
                Text("\nActivity Rings:")
                    .bold()
                Text("Move: \(Int(metrics!.moveRingProgress * 100))%")
                Text("Exercise: \(Int(metrics!.exerciseRingProgress * 100))%")
                Text("Stand: \(Int(metrics!.standRingProgress * 100))%")
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
                    metrics = try await metricsManager.fetchAllMetrics()
                } catch {
                    print("Error fetching metrics: \(error)")
                }
            }
        }
    }
}

#Preview {
    HealthDataView()
}
