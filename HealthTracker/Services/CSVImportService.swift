//
//  CSVImportService.swift
//  HealthTracker/Services
//

import Foundation
import SwiftData

enum CSVImportService {
    static func importSatisfactionEntries(from url: URL, into context: ModelContext) {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            return
        }

        let rows = text.split(separator: "\n").map { String($0) }
        guard !rows.isEmpty else { return }

        let header = rows[0].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for row in rows.dropFirst() {
            let cols = row.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if cols.count < 2 { continue }

            guard
                let dateIdx = header.firstIndex(of: "date"),
                let scoreIdx = header.firstIndex(of: "satisfaction"),
                dateIdx < cols.count,
                scoreIdx < cols.count
            else { continue }

            let dateString = cols[dateIdx]
            guard let day = formatter.date(from: dateString)?.startOfDay else { continue }

            let score = Int(cols[scoreIdx]) ?? 0

            let descriptor = FetchDescriptor<SatisfactionEntry>(
                predicate: #Predicate { $0.day == day },
                sortBy: []
            )
            let existing = (try? context.fetch(descriptor).first) ?? nil
            let entry = existing ?? SatisfactionEntry(day: day, score: score)

            entry.score = score

            func doubleFromHeader(_ name: String) -> Double? {
                guard let idx = header.firstIndex(of: name), idx < cols.count else { return nil }
                return Double(cols[idx])
            }

            entry.stepsToday = doubleFromHeader("stepsToday") ?? entry.stepsToday
            entry.timeInBedLastNight = doubleFromHeader("timeInBedLastNight") ?? entry.timeInBedLastNight
            entry.activeEnergyToday = doubleFromHeader("activeEnergyToday") ?? entry.activeEnergyToday
            entry.exerciseMinutesToday = doubleFromHeader("exerciseMinutesToday") ?? entry.exerciseMinutesToday
            entry.standHoursToday = doubleFromHeader("standHoursToday") ?? entry.standHoursToday
            entry.daylightTimeToday = doubleFromHeader("daylightTimeToday") ?? entry.daylightTimeToday
            entry.distanceWalkingToday = doubleFromHeader("distanceWalkingToday") ?? entry.distanceWalkingToday
            entry.flightsClimbedToday = doubleFromHeader("flightsClimbedToday") ?? entry.flightsClimbedToday
            if let val = doubleFromHeader("restingHeartRateToday") {
                entry.restingHeartRateToday = val
            }

            if existing == nil {
                context.insert(entry)
            }
        }

        try? context.save()
    }
}

private extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}