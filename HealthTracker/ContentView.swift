//
//  ContentView.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 10/24/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    var body: some View {
        if !HKHealthStore.isHealthDataAvailable() {
            Text("Health Data is not available on this device")
        } else {
            TabView {
                Tab("Survey", systemImage: "checklist") {
                    SurveyView()
                }
                Tab("Suggestions", systemImage: "heart.text.clipboard") {
                    SuggestionsView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
