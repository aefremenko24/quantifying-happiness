//
//  SatisfactionEntry.swift
//  HealthTracker/Schemas
//

import SwiftData
import Foundation

@Model
final class SatisfactionEntry {
    @Attribute(.unique) var day: Date

    var userSatisfactionScore: Int?

    var stepsToday: Double
    var timeInBedLastNight: Double
    var activeEnergyToday: Double
    var exerciseMinutesToday: Double
    var standHoursToday: Double
    var daylightTimeToday: Double
    var distanceWalkingToday: Double
    var flightsClimbedToday: Double
    var restingHeartRateToday: Double?

    init(day: Date,
         score: Int? = nil,
         stepsToday: Double = 0,
         timeInBedLastNight: Double = 0,
         activeEnergyToday: Double = 0,
         exerciseMinutesToday: Double = 0,
         standHoursToday: Double = 0,
         daylightTimeToday: Double = 0,
         distanceWalkingToday: Double = 0,
         flightsClimbedToday: Double = 0,
         restingHeartRateToday: Double? = nil) {

        self.day = Calendar.current.startOfDay(for: day)
        self.userSatisfactionScore = score
        self.stepsToday = stepsToday
        self.timeInBedLastNight = timeInBedLastNight
        self.activeEnergyToday = activeEnergyToday
        self.exerciseMinutesToday = exerciseMinutesToday
        self.standHoursToday = standHoursToday
        self.daylightTimeToday = daylightTimeToday
        self.distanceWalkingToday = distanceWalkingToday
        self.flightsClimbedToday = flightsClimbedToday
        self.restingHeartRateToday = restingHeartRateToday
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
