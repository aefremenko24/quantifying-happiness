//
//  HomeView.swift
//  HealthTracker/Views
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Binding var selectedDate: Date
    @State private var entry: SatisfactionEntry?

    var body: some View {
        VStack {
            HStack {
                Text(selectedDate, format: Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated))
                    .font(.title).bold().padding(.vertical, 8)
                Spacer()
            }
            .padding(.horizontal)

            if let entry {
                SatisfactionScoreEntryView(
                    satisfactionScore: Binding<Float>(
                        get: { Float(entry.score ?? 5) },
                        set: { newVal in
                            entry.score = Int(newVal.rounded())
                            try? context.save()
                        }
                    )
                )
                .padding(.horizontal)
            } else {
                Text("Loading…")
            }

            HealthDataView()
                .padding(.top, 8)

            SuggestionsView()
                .padding(.top, 8)

            Spacer()
        }
        .navigationTitle("Home")
        .onAppear { ensureEntry() }
        .onChange(of: selectedDate) { _, _ in ensureEntry() }
    }

    // Helper Method to look up an entry for the current day selected and load it if it exists, if not, it will create a new entry.
    private func ensureEntry() {
        let day = selectedDate.startOfDay
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day == day },
            sortBy: []
        )

        if let existing = try? context.fetch(descriptor).first {
            entry = existing
            return
        }

        let newEntry = SatisfactionEntry(day: day, score: nil)
        context.insert(newEntry)
        try? context.save()
        entry = newEntry
    }
}