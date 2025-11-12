//
//  Item.swift
//  HealthTracker/Schemas
//

import Foundation
import SwiftData

@Model
final class SatisfactionEntry {
    var day: Date
    var score: Int?

    init(day: Date, score: Int? = nil) {
        self.day = Calendar.current.startOfDay(for: day)
        self.score = score
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
