//
//  ContentView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/24/25.
//

import SwiftUI
import HealthKit
import SwiftData

struct ContentView: View {
    private enum Tab { case home, calendar }

    @State private var selectedTab: Tab = .home
    
    @Environment(\.modelContext) private var context

    var body: some View {
        if !HKHealthStore.isHealthDataAvailable() {
            Text("Health Data is not available on this device")
        } else {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                        .padding(.vertical, 10)
                }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

                NavigationStack {
                    CalendarView(
                        selectedDate: Date(),
                        onImportCSV: { url in
                            CSVImportService.importSatisfactionEntries(from: url, into: context)
                        }
                    )
                    .padding(.vertical, 10)
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)
            }
        }
    }
}

#Preview { 
    ContentView() 
}
