//
//  HomeView.swift
//  HealthTracker/Views
//

import SwiftUI
import SwiftData

/// Displays the main home screen, allowing the user to record
/// how happy they feel today and view personalized suggestions.
///
/// 'HomeView' loads (or creates) today's 'SatisfactionEntry' on appear.
/// It allows the user to adjust their daily satisfaction score and
/// automatically saves updates to SwiftData. It also retrieves the most
/// recent valid past entry to generate suggestions.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var entry: SatisfactionEntry?
    @State private var lastValidEntry: SatisfactionEntry?

    var body: some View {
        ScrollView {
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
                    if let lastValidEntry {
                        SuggestionsView(currentSatisfactionEntry: lastValidEntry)
                            .padding(.top, 8)
                    } else {
                        Text("Loading suggestions...").foregroundStyle(.secondary)
                    }
                } else {
                    Text("Loading...").foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle(Date().formatted(
                 Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated))
        )
        .onAppear {
            ensureEntry()
            fetchLastValidEntry()
        }
    }



    /// Retrieves the 'SatisfactionEntry' stored for a given day.
    ///
    /// Normalizes the incoming date to midnight and queries the
    /// persistent SwiftData store for an entry that matches that day.
    ///
    /// - Parameters:
    ///   - day: The calendar day to retrieve an entry for.
    /// - Returns:
    ///   - 'SatisfactionEntry?' - A 'SatisfactionEntry' for that day if one exists, otherwise 'nil'.
    private func fetchEntry(for day: Date) -> SatisfactionEntry? {
        let dayStart = day.startOfDay
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: []
        )
        return (try? context.fetch(descriptor).first) ?? nil
    }

    /// Ensures that a satisfaction entry exists for today's date.
    ///
    /// If the database already contains an entry for today, it is loaded into
    /// the view state. If not, a new entry is created, inserted into the
    /// SwiftData context, saved, and then assigned to 'entry'.
    ///
    /// This method guarantees that the user always has an editable record
    /// for the current day.
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

    /// Fetches the most recent entry that contains a valid (not nil) satisfaction score.
    ///
    /// This is used to generate suggestions based on the user's most recent
    /// meaningful input. If no historical valid entries exist, today's
    /// entry is used instead.
    ///
    /// Updates the `lastValidEntry` state property with the most recent
    /// entry containing a score, or today's entry if none exist.
    private func fetchLastValidEntry() {
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.userSatisfactionScore != nil },
            sortBy: [ SortDescriptor(\SatisfactionEntry.day, order: .forward) ]
        )
        if let validEntry = try? context.fetch(descriptor).dropLast().last {
            lastValidEntry = validEntry
        } else {
            lastValidEntry = self.entry
        }
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = Date()
    
    HomeView()
}
