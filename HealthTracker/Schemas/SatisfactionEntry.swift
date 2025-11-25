//
//  SatisfactionEntry.swift
//  HealthTracker/Schemas
//

import SwiftData
import Foundation

// Custom errors
private enum SatisfactionEntryError: Error {
    case valueError(String)
}

@Model
final class SatisfactionEntry {
    @Attribute(.unique) var day: Date
    
    var userSatisfactionScore: Double?      // [0, 10]
    
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
         score: Double?,
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
    
    init?(from list: [Double], satisfactionScore: Double) {
        guard list.count == 9 else {
            return nil
        }
        
        self.day = Date().startOfDay
        self.userSatisfactionScore = satisfactionScore

        self.stepsToday = list[0]
        self.timeInBedLastNight = list[1]
        self.activeEnergyToday = list[2]
        self.exerciseMinutesToday = list[3]
        self.standHoursToday = list[4]
        self.daylightTimeToday = list[5]
        self.distanceWalkingToday = list[6]
        self.flightsClimbedToday = list[7]
        self.restingHeartRateToday = list[8]
        
    }
    
    init(from healthMetrics: HealthMetrics, date: Date, satisfactionScore: Double) {
        self.day = date
        self.userSatisfactionScore = satisfactionScore
        
        self.stepsToday = healthMetrics.stepsToday
        self.timeInBedLastNight = healthMetrics.timeInBedLastNight
        self.activeEnergyToday = healthMetrics.activeEnergyToday
        self.exerciseMinutesToday = healthMetrics.exerciseMinutesToday
        self.standHoursToday = healthMetrics.standHoursToday
        self.daylightTimeToday = healthMetrics.daylightTimeToday
        self.distanceWalkingToday = healthMetrics.distanceWalkingToday
        self.flightsClimbedToday = healthMetrics.flightsClimbedToday
        self.restingHeartRateToday = healthMetrics.restingHeartRateToday
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
    
    static func metricNamesList() -> [String] {
        return [
            "Steps taken",
            "Time in Bed",
            "Calories Burnt",
            "Minutes Exercising",
            "Stand Hours",
            "Daylight Time",
            "Distance Walked",
            "Flights Climbed"
        ]
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
