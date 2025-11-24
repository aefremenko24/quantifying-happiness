//
//  SatisfactionEntry.swift
//  HealthTracker/Schemas
//

import SwiftData
import Foundation

@Model
final class SatisfactionEntry {
    @Attribute(.unique) var day: Date
    
    var userSatisfactionScore: Double       // [0, 10]
    
    var stepsToday: Double                  // [0, 20000]
    var timeInBedLastNight: Double          // [0, 20]
    var activeEnergyToday: Double           // [0, 2000]
    var exerciseMinutesToday: Double        // [0, 1000]
    var standHoursToday: Double             // [0, 24]
    var daylightTimeToday: Double           // [0, 24]
    var distanceWalkingToday: Double        // [0, 40000]
    var flightsClimbedToday: Double         // [0, 100]
    var restingHeartRateToday: Double       // [0, 200]

    init(day: Date,
         score: Double = 0,
         stepsToday: Double = 0,
         timeInBedLastNight: Double = 0,
         activeEnergyToday: Double = 0,
         exerciseMinutesToday: Double = 0,
         standHoursToday: Double = 0,
         daylightTimeToday: Double = 0,
         distanceWalkingToday: Double = 0,
         flightsClimbedToday: Double = 0,
         restingHeartRateToday: Double = 0) {

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
    
    func toList() -> [Double] {
        return [
            self.stepsToday,
            self.timeInBedLastNight,
            self.activeEnergyToday,
            self.exerciseMinutesToday,
            self.standHoursToday,
            self.daylightTimeToday,
            self.distanceWalkingToday,
            self.flightsClimbedToday,
            self.restingHeartRateToday,
        ]
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
