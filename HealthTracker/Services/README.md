
# Step by Step Guide on how to upload data to the App using a CSV with pre-populated data.

Each imported row is stored as a SatisfactionEntry object (one per day).
If an entry for a given day already exists, it will be updated, not duplicated.

# Step 1. Formatting the CSV file

The CSV must have a header row, then each subsequent row must be a separate entry.

HEADER FORMAT AT TOP:
date,satisfaction,stepsToday,timeInBedLastNight,activeEnergyToday,exerciseMinutesToday,standHoursToday,daylightTimeToday,distanceWalkingToday,flightsClimbedToday,restingHeartRateToday

Required Columns:
date – the calendar day for this entry (YYYY-MM-DD format, date)
satisfaction – the user’s satisfaction score for that day (0–10 int)

Optional Columns:
stepsToday – total step count for the day (integer or double)
timeInBedLastNight – minutes spent in bed for the preceding night (double)
activeEnergyToday – active energy burned in kilocalories (double)
exerciseMinutesToday – minutes of exercise (double)
standHoursToday – number of standing hours (double)
daylightTimeToday – minutes spent in daylight (double)
distanceWalkingToday – distance walked/run in meters (double)
flightsClimbedToday – number of flights of stairs climbed (double)
restingHeartRateToday – resting heart rate in beats per minute (double)

Example CSV File:

date,satisfaction,stepsToday,timeInBedLastNight,activeEnergyToday,exerciseMinutesToday,standHoursToday,daylightTimeToday,distanceWalkingToday,flightsClimbedToday,restingHeartRateToday
2025-10-26, 7, 8234, 420, 570, 32, 13, 60, 4350, 10, 58
2025-10-27, 5, 3500, 300, 250, 10, 8, 15, 1200, 3, 65

# Step 2. How to import the CSV file in the app

Open the app and navigate to the Calendar view.
Tap the “Import CSV Data” button below the calendar.
Choose your .csv file.
The app will parse the file and create or update SatisfactionEntry rows.
The calendar will refresh and show scores for any days that now have data.

