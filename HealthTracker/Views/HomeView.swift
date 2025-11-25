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
        VStack(alignment: .center, spacing: 16) {
            Group {
                if let entry {
                    Text("How happy are you today?")
                        .fontWeight(.bold)
                    SatisfactionScoreEntryView(
                        satisfactionScore: Binding<Int>(
                            get: { Int(entry.userSatisfactionScore ?? 5) },
                            set: { newVal in
                                entry.userSatisfactionScore = Double(newVal)
                                try? context.save()
                            }
                        )
                    )
                } else {
                    Text("Loading…").foregroundStyle(.secondary)
                }
            }

            HealthDataView()
                .padding(.top, 8)

            SuggestionsView()
                .padding(.top, 8)

            Spacer()

            if entry != nil {
                Button(role: .destructive) {
                    deleteCurrentEntry()
                } label: {
                    Text("Delete Entry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle(selectedDate.formatted(
                 Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated))
        )
        .onAppear { ensureEntry() }
        .onChange(of: selectedDate) { _, _ in ensureEntry() }
    }


    // Helper method to fetch the entry for a specific date (if there exists one)
    private func fetchEntry(for day: Date) -> SatisfactionEntry? {
        let dayStart = day.startOfDay
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: []
        )
        return (try? context.fetch(descriptor).first) ?? nil
    }

    // Helper Method to look up an entry for the current day selected and load it if it exists, if not, it will create an entry.
    private func ensureEntry() {
        let day = selectedDate.startOfDay
        if let existing = fetchEntry(for: day) {
            entry = existing
        } else {
            let newEntry = SatisfactionEntry(day: day, score: nil)
            context.insert(newEntry)
            try? context.save()
            entry = newEntry
        }
    }

    // Helper Method to delete an entry for the current day selected (only shows up if there is an entry for that day)
    private func deleteCurrentEntry() {
        guard let entry 
        else { return }
        context.delete(entry)
        try? context.save()
        self.entry = nil
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = Date()
    
    HomeView(selectedDate: $selectedDate)
}
