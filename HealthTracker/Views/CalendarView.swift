//
//  CalendarView.swift
//  HealthTracker/Views
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers


/// An interactive calendar for viewing and editing daily satisfaction entries.
///
/// 'CalendarView' displays a full month grid, highlights the selected date,
/// shows user satisfaction scores 0 to 10 for each day, and allows the user to:
///  - create or edit a `SatisfactionEntry` for a specific date,
///  - delete an existing entry,
///  - import additional entries from a CSV file,
///  - navigate between months.
///
/// The view automatically fetches all `SatisfactionEntry` records for the
/// currently visible month using SwiftData and caches them in a dictionary.
/// It also presents a detail sheet when a day is tapped, letting the user
/// update their satisfaction score.
///
/// - Parameters:
///   - selectedDate: The date initially selected when the view loads.
///   - onImportCSV: A callback executed when the user imports a CSV file. 
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
            loadScores()
        } content: {
            SatisfactionEntryView(date: selectedDate.startOfDay, satisfactionEntry: $entry) {
                try? context.save()
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

    /// Renders a single calendar grid cell for the provided day.
    /// When tapped, the cell loads or creates the associated 'SatisfactionEntry'
    /// and shows the entry view for that day with the statistics.
    ///
    /// Displays: the day number, an optional satisfaction score,
    /// a background color reflecting the user's satisfaction score.
    ///
    /// - Parameters:
    ///   - day: The date represented by this calendar cell.
    @ViewBuilder
    private func dayCell(day: Date) -> some View {
        let score = scoresByDay[day.startOfDay]
        Button {
            self.selectedDate = day
            ensureEntry()
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

    /// Fetches the existing 'SatisfactionEntry' for a given day, if any.
    ///
    /// - Parameters:
    ///   - day: A calendar date.
    /// - Returns: 
    ///   - 'date?': The existing entry for that date, or 'nil' if none exists.
    private func fetchEntry(for day: Date) -> SatisfactionEntry? {
        let dayStart = day.startOfDay
        let descriptor = FetchDescriptor<SatisfactionEntry>(
            predicate: #Predicate { $0.day == dayStart },
            sortBy: []
        )
        return (try? context.fetch(descriptor).first) ?? nil
    }
    
    /// Ensures that an entry exists for 'selectedDate'.
    ///
    /// If an entry is already stored for that date, it is loaded into 'entry'.
    /// Otherwise, a new 'SatisfactionEntry' is created, inserted into the context,
    /// saved, and then assigned to 'entry'.
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
    
    /// Deletes the currently selected satisfaction entry, if any, from storage.
    ///
    /// After deletion, the view refreshes cached scores and clears the 'entry' state.
    private func deleteCurrentEntry() {
        guard let entry
        else { return }
        context.delete(entry)
        try? context.save()
        self.entry = nil
        loadScores()
    }
    
    /// Loads all satisfaction scores for the visible month into 'scoresByDay'.
    ///
    /// Fetches 'SatisfactionEntry' objects within the month range, extracts their
    /// scores, clamps values to 0-10, and stores them in a dictionary keyed by day.
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

    /// Computes the date range covering the visible month (relative to midnight).
    ///
    /// - Returns: A tuple containing:
    ///   - start: the first day of the current month.
    ///   - end: the first day of the next month.
    private func monthDateRange() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthAnchor)
        let start = cal.date(from: comps)!.startOfDay
        let end = cal.date(byAdding: .month, value: 1, to: start)!.startOfDay
        return (start, end)
    }

    /// Builds the grid representation of the month, including padding cells.
    ///
    /// Produces an array of optional dates where:
    ///  - leading 'nil' values align and pad the first day to the correct weekday,
    ///  - actual dates fill the remainder of the month,
    ///  - trailing 'nil' values complete and pad the final row so the grid is rectangular.
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

    /// Maps a satisfaction score to a color gradient.
    ///
    /// Scores near 0 appear red, middle ranged scores appear yellow,
    /// and high scores approach green.
    ///
    /// - Parameters:
    ///   - score: Optional daily satisfaction value.
    /// - Returns: A tuple containing:
    ///   - 'Color': A background `Color` appropriate for that score.
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
