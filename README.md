# Quantifying Happiness: Health Metrics and Wellbeing Optimization

## Overview

HealthTracker is an iOS application that analyzes the correlation between user's health metrics and their self-reported satisfaction levels to provide useful health suggestions.

The project was developed with the goal of answering three key questions:

1. Is there a correlation between the user's health data and how satisfied they are?
2. Can this correlation be used to make meaningful predictions and suggestions to give users more satisfaction?
3. Can we detect impactful patterns that drive this correlation that the user might not be aware of?

## Features

### Health Data Integration
- Integration with Apple HealthKit to automatically fetch daily health metrics
- Supports 9 health indicators:
  - Steps Taken (count)
  - Time in Bed (minutes)
  - Active Energy/Calories Burnt (kcal)
  - Exercise Minutes (minutes)
  - Stand Hours (count)
  - Daylight Time (minutes)
  - Distance Walked (meters)
  - Flights Climbed (count)
  - Resting Heart Rate (bpm)

### Satisfaction Tracking
- Daily prompts to log how the user is feeling on a scale from 1 to 10
- Calendar view for convenient historical view and retroactive satisfaction scores entry 

### Suggestions Model
- Simulated Annealing Optimization: Searches for optimal health metric targets that maximize predicted satisfaction
- Home view automatically updates and displays personalized recommendations showing which metrics to increase or decrease

### Data Management
- Persistent local storage using SwiftData
- CSV import functionality for bulk data upload

## Technical Implementation

### Simulated Annealing Optimization

We chose the Simulated Annealing algorithm for optimization because:
- Starting out, each user will have a limited amount of data. Simulated Annealing works immediately with any number of data points.
- We care about finding the global maximum of a noisy landscape. The probabilistic acceptance of worse solutions helps escape local optima.

Parameters we found worked best:
- Initial Temperature: 100.0
- Cooling Rate: 0.95
- Step Size: 0.25
- Num Iterations: 500-2000

### K-Nearest Neighbors (KNN) Regression

To allow the Simulated Annealing algorithm to take steps in any direction, we needed a way of estimating satisfaction scores for parameter combinations not seen in the training data.

We chose KNN because:
- It works immediately with any amount of data.
- It is able to capture complex, potentially non-linear relationships without explicit modeling.
- In our implementation, it cannot extrapolate beyond training data range, preventing unrealistic/dangerous suggestions.

## Project Structure

```
quantifying-happiness/
├── README.md                                       # This file
│
├── HealthTracker/                                  # Main app target
│   ├── Model/
│   │   ├── HealthKitDataManager.swift              # HealthKit integration for data fetching
│   │   ├── FeatureScaler.swift                     # Data normalization
│   │   ├── KNNRegressor.swift                      # K-Nearest Neighbors implementation
│   │   └── SimulatedAnnealingOptimizer.swift       # Simulated Annealing implementation
│   │
│   ├── Schemas/
│   │   └── SatisfactionEntry.swift                 # Data model for satisfaction entries
│   │
│   ├── Services/
│   │   ├── CSVImportService.swift                  # CSV file import
│   │   └── README.md                               # CSV import documentation
│   │
│   ├── Views/
│   │   ├── ContentView.swift                       # Root view containing tabs to Home and Calendar views
│   │   ├── HomeView.swift                          # Main view for today's suggestions
│   │   ├── CalendarView.swift                      # Calendar view for historical data
│   │   └── SubViews/
│   │       ├── SatisfactionEntryView.swift         # Child view for a single-day-data preview
│   │       ├── SatisfactionScoreEntryView.swift    # Child view for score input
│   │       └── SuggestionsView.swift               # Child view for the model suggestions
│   │
│   ├── HealthTracker.entitlements                  # HealthKit entitlements
│   └── HealthTrackerApp.swift                      # Main app entry point
│
└── HealthTrackerTests/                             # Test target
    ├── SampleData.json                             # Synthetic test dataset
    ├── FeatureScalerTests.swift                    # Unit tests for the Feature Scaler
    ├── KNNRegressorTests.swift                     # Unit tests for the KNN Regressor
    ├── SimulatedAnnealingOptimizerTests.swift      # Integration tests for the Optimizer
    ├── TestDataLoader.swift                        # Utilities for loading test data
    └── README.md                                   # Test data documentation
```

## Running the Application

### Prerequisites

- macOS 14.5 or later
- Xcode 16.0 or later
- iOS Device or Simulator running iOS 18.0 or later
- Free Apple Developer Account

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/aefremenko24/quantifying-happiness.git
   cd HealthTracker
   ```

2. Open the project in Xcode:
   ```bash
   open HealthTracker.xcodeproj
   ```

3. Configure signing:
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your development team

4. Build and run:
   - Select your target device or simulator
   - Press `Cmd + R` or click the Run button

## Running Tests

The project includes unit and integration tests written using the Swift Testing framework. We highly recommend that you run the tests if you don't have a device HealthKit data to try the app on.

### Running Tests in Xcode

1. Open the Test Navigator:
   - Press `Cmd + 6` or go to View > Navigators > Tests

2. To run all tests:
   - Press `Cmd + U` Or click the Run button next to "HealthTrackerTests" in the Test Navigator

3. To run specific test files:
   - Click the Run button next to individual test files

### Running Tests from Command Line

```bash
xcodebuild test \
  -project HealthTracker.xcodeproj \
  -scheme HealthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**NOTE**: Test data in `SampleData.json` is synthetically generated and does not represent real user data.

## TestFlight

The latest stable build of this repository is also available on TestFlight: [Join the Beta](https://testflight.apple.com/join/y1Q6tUnS)

## Authors

- **Arthur Efremenko**
- **Ben Shainman**
- **Patrick Flanagan**
- **Cevdet Isik**

## Acknowledgments

The project uses the following frameworks:

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [SwiftData Framework](https://developer.apple.com/documentation/swiftdata)
- [Swift Testing](https://developer.apple.com/documentation/testing)

In addition, synthetic test data is generated with assistance from Claude (Anthropic)
