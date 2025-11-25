//
//  HomeView.swift
//  HealthTracker/Views
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var entry: SatisfactionEntry?

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if let entry {
                Text("How happy are you today?")
                    .fontWeight(.bold)
                SatisfactionScoreEntryView(
                    satisfactionScore: Binding<Int?>(
                        get: { Int(entry.userSatisfactionScore ?? 5) },
                        set: { newVal in
                            entry.userSatisfactionScore = newVal == nil ? nil : Double(newVal!)
                            try? context.save()
                        }
                    )
                )
                ScrollView {
                    SuggestionsView(currentSatisfactionEntry: entry)
                        .padding(.top, 8)
                }
            } else {
                Text("Loading...").foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .navigationTitle(Date().formatted(
                 Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated))
        )
        .onAppear { ensureEntry() }
    }


    private func fetchEntry(for day: Date) -> SatisfactionEntry? {
        let dayStart = day.startOfDay
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: []
        )
        return (try? context.fetch(descriptor).first) ?? nil
    }

    private func ensureEntry() {
        if let existing = fetchEntry(for: Date()) {
            entry = existing
        } else {
            let newEntry = SatisfactionEntry(day: Date(), score: nil)
            context.insert(newEntry)
            try? context.save()
            entry = newEntry
        }
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = Date()
    
    HomeView()
}
