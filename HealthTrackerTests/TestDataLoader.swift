//
//  TestDataLoader.swift
//  HealthTrackerTests
//
//  Created by Arthur Efremenko on 11/25/25.
//

import Foundation

// Custom errors
private enum TestDataLoaderError: Error {
    case fileNotFoundError(String)
}

struct TestDataEntry: Codable {
    let date: String
    let satisfactionScore: Double
    let metrics: [Double]
}

struct TestData: Codable {
    let entries: [TestDataEntry]
}

func loadTestData(from jsonData: Data) throws -> [SatisfactionEntry] {
    let decoder = JSONDecoder()
    let testData = try decoder.decode(TestData.self, from: jsonData)
    
    let dateFormatter = ISO8601DateFormatter()
    
    return testData.entries.compactMap { entry in
        guard let date = dateFormatter.date(from: entry.date) else {
            print("Failed to parse date '\(entry.date)'")
            return nil
        }
        
        guard let satisfactionEntry = SatisfactionEntry(
            from: entry.metrics,
            satisfactionScore: entry.satisfactionScore
        ) else {
            print("Failed to create SatisfactionEntry from metrics array")
            return nil
        }
        
        satisfactionEntry.day = Calendar.current.startOfDay(for: date)
        
        return satisfactionEntry
    }
}

func loadTestDataFromFile(named filename: String = "SampleData") throws -> [SatisfactionEntry] {    
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
        throw TestDataLoaderError.fileNotFoundError("Could not find \(filename).json in bundle")
    }
    
    let data = try Data(contentsOf: url)
    return try loadTestData(from: data)
}
