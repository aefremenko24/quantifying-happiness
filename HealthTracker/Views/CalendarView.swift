//
//  CalendarView.swift
//  HealthTracker/Views
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct CalendarView: View {
    @Environment(\.modelContext) private var context

    @State var selectedDate: Date
    @State private var monthAnchor: Date = Date().startOfDay
    @State private var scoresByDay: [Date: Double] = [:]
    @State private var showingImporter: Bool = false
    @State private var showingDayDetails: Bool = false
    @State private var entry: SatisfactionEntry?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    let onImportCSV: (URL) -> Void

    var body: some View {
        VStack(spacing: 20) {
            header
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(cellsForMonth(), id: \.self) { cell in
                    if let day = cell {
                        dayCell(day: day)
                    } else {
                        Rectangle().fill(Color.clear).aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 8)
            
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
            }
            
            Button {
                showingImporter = true
            } label: {
                Text("Import CSV Data")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.bottom, 8)
                
        }
        .navigationTitle("Calendar")
        .onAppear(perform: loadScores)
        .onChange(of: monthAnchor) { _, _ in loadScores() }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onImportCSV(url)
                    loadScores()
                }
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
        .sheet(isPresented: $showingDayDetails) {
            SatisfactionEntryView(date: selectedDate.startOfDay, satisfactionEntry: $entry) { newEntry in
                context.insert(newEntry)
                try? context.save()
                loadScores()
            }
            .presentationDragIndicator(.visible)
        }
    }


    // Top bar of the calendar showing month name with left and right arrows to navigate months
    private var header: some View {
        HStack {
            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
            } label: { Image(systemName: "chevron.left") }

            Spacer()

            Text(monthAnchor, format: .dateTime.month(.wide).year())
                .font(.title3).bold()

            Spacer()

            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
            } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
    }

    // Row showing Sunday to Saturday
    private var weekdayHeader: some View {
        HStack {
            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { s in
                Text(s)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
    }

    // One calendar cell which shows day number, optional user satisfaction score, and a color fill based on that score
    @ViewBuilder
    private func dayCell(day: Date) -> some View {
        let score = scoresByDay[day.startOfDay]
        Button {
            self.selectedDate = day
            self.showingDayDetails = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(day == selectedDate ? Color.blue :  Color.secondary.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor(for: score))
                    )
                VStack(spacing: 2) {
                    Text(day, format: .dateTime.day())
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 4).padding(.leading, 4)

                    Spacer()

                    if let score {
                        Text("\(Int(score))")
                            .font(.headline)
                            .padding(.bottom, 6)
                    }
                }
                .padding(4)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
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
    
    // Fetches all SatisfactionEntry rows that fall within the visible month and caches them in a dictionary keyed by day
    private func loadScores() {
        let (start, end) = monthDateRange()
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day >= start && $0.day < end }
        )
        if let entries = try? context.fetch(descriptor) {
            var map: [Date: Double] = [:]
            for e in entries {
                if let s = e.userSatisfactionScore {
                    map[e.day.startOfDay] = min(10.0, max(0.0, s))
                }
            }
            scoresByDay = map
        }
    }

    // Calculates the first day of the current month and the first day of next month for a date range
    private func monthDateRange() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthAnchor)
        let start = cal.date(from: comps)!.startOfDay
        let end = cal.date(byAdding: .month, value: 1, to: start)!.startOfDay
        return (start, end)
    }

    // Produces the grid cells for the month with empty spaces for the first week offset, followed by actual Date values for each day and then trailing empty spaces to complete the last week row
    private func cellsForMonth() -> [Date?] {
        let cal = Calendar.current
        let (start, _) = monthDateRange()

        let weekdayIndex = cal.component(.weekday, from: start)
        let leading = (weekdayIndex - cal.firstWeekday + 7) % 7

        let days = cal.range(of: .day, in: .month, for: start)!.count

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<days {
            cells.append(cal.date(byAdding: .day, value: d, to: start)!)
        }

        let remainder = cells.count % 7
        if remainder != 0 { cells += Array(repeating: nil, count: 7 - remainder) }
        return cells
    }

    // Helper function to map user satisfaction score to a color where closer to 0 is red, yellow is around 5, and green is 10
    private func backgroundColor(for score: Double?) -> Color {
        guard let score = score else { return .clear }
        let t = Double(score) / 10.0
        if t <= 0.5 {
            let p = t / 0.5
            return Color(red: 1, green: p, blue: 0, opacity: 0.15 + 0.35*p)
        } else {
            let p = (t - 0.5) / 0.5
            return Color(red: 1 - p, green: 1, blue: 0, opacity: 0.5 + 0.4*p)
        }
    }
    
}

#Preview {
    CalendarView(selectedDate: Date(), onImportCSV: {_ in})
}
