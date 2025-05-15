//
//  AchievementTests.swift
//  HabitTrackerTests
//
//  Created by Volodymyr Boichentsov on 04/04/2025.
//

import XCTest
import SwiftData
@testable import HabitTracker

final class AchievementTests: XCTestCase {
    
    var modelData: ModelData!
    var mockContext: ModelContext!
    var testHabit: HabitItem!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Set up test environment asynchronously
        let expectation = XCTestExpectation(description: "Setup completed")
        
        Task { @MainActor in
            // Set up in-memory container for testing
            let schema = Schema(versionedSchema: SchemaLatest.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            modelData = ModelData()
            modelData.modelContainer = container
            mockContext = container.mainContext
            
            // Create a test habit
            let testCategory = HabitCategory(id: "test", title: "Test Category", color: "#FFFFFF")
            mockContext.insert(testCategory)
            
            testHabit = HabitItem(
                title: "Test Habit",
                color: "#FF0000",
                category: testCategory,
                timestamp: Date().addingTimeInterval(-1000 * 86400) // Created 1000 days ago
            )
            mockContext.insert(testHabit)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
        modelData = nil
        testHabit = nil
        try super.tearDownWithError()
    }
    
    // Helper method to run async tasks in tests
    func runAsyncTest(testBlock: @escaping () async -> Void) {
        let expectation = XCTestExpectation(description: "Async test")
        Task { @MainActor in
            await testBlock()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a sequence of daily entries with specified completion pattern
    func createEntrySequence(daysCount: Int, completedDays: Set<Int>, startDate: Date = Date()) {
        // Clear any existing entries
        let descriptor = FetchDescriptor<DailyEntry>()
        if let existingEntries = try? mockContext.fetch(descriptor) {
            for entry in existingEntries {
                mockContext.delete(entry)
            }
        }
        try? mockContext.save()
        
        let calendar = Calendar.current
        for i in 0..<daysCount {
            let entryDate = calendar.date(byAdding: .day, value: -i, to: startDate)!
            let isCompleted = completedDays.contains(i)
            let entry = DailyEntry(
                habit: testHabit,
                date: entryDate,
                isCompleted: isCompleted,
                completionDate: isCompleted ? entryDate : nil
            )
            mockContext.insert(entry)
        }
        try? mockContext.save()
    }
    
    // Helper method to get the most recent entry
    func getLatestEntry() -> DailyEntry? {
        let descriptor = FetchDescriptor<DailyEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try? mockContext.fetch(descriptor).first
    }
    
    // MARK: - Streak Achievement Tests
    
    func testCompletionStreakWeek() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 7, completedDays: Set(0..<7))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionStreakWeek, "7-day streak should return .completionStreakWeek")
        }
    }
    
    func testCompletionStreakWeekPlusday() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 8, completedDays: Set(0..<8))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "8-day streak should return .none")
        }
    }
    
    func testCompletionStreak2Weeks() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 14, completedDays: Set(0..<14))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionStreak2Weeks, "14-day streak should return .completionStreak2Weeks")
        }
    }
    
    func testCompletionMonth() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 30, completedDays: Set(0..<30))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionMonth, "30-day streak should return .completionMonth")
        }
    }
    
    func testCompletionStreak50() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 50, completedDays: Set(0..<50))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionStreak50, "50-day streak should return .completionStreak50")
        }
    }
    
    func testCompletionStreak100() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 100, completedDays: Set(0..<100))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionStreak100, "100-day streak should return .completionStreak100")
        }
    }
    
    // MARK: - Total Completion Tests
    
    func testCompletionTotal30() throws {
        runAsyncTest {
            var completedDays = Set<Int>()
            for i in 0..<60 where i % 2 == 0 {  // Complete every other day for 60 days = 30 completions
                completedDays.insert(i)
            }
            self.createEntrySequence(daysCount: 60, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionTotal30, "30 total completions should return .completionTotal30")
        }
    }
    
    func testCompletionTotal66() throws {
        runAsyncTest {
            var completedDays = Set<Int>()
            for i in 0..<132 where i % 2 == 0 {  // Complete every other day for 132 days = 66 completions
                completedDays.insert(i)
            }
            self.createEntrySequence(daysCount: 132, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionTotal66, "66 total completions should return .completionTotal66")
        }
    }
    
    // MARK: - Renewed Habit Tests
    
    func testCompletionRenewed() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 10, completedDays: [5])
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionRenewed, "Completion after 5 days should return .completionRenewed")
        }
    }
    
    func testCompletionRenewed2() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 25, completedDays: [20])
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionRenewed2, "Completion after 20 days should return .completionRenewed2")
        }
    }
    
    func testCompletionRenewed3() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 40, completedDays: [35])
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionRenewed3, "Completion after 35 days should return .completionRenewed3")
        }
    }
    
    func testNoAchievement() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 5, completedDays: [1, 3])
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "No special conditions met should return .none")
        }
    }
    
    // MARK: - Additional Streak Tests
    
    func testCompletionYear() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 365, completedDays: Set(0..<365))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionYear, "365-day streak should return .completionYear")
        }
    }
    
    func testBrokenStreak() throws {
        runAsyncTest {
            // Create a 7-day sequence with a break in the middle
            var completedDays = Set(0..<7)
            completedDays.remove(3) // Break the streak in the middle
            self.createEntrySequence(daysCount: 7, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "Broken streak should return .none")
        }
    }
    
    func testIncompleteEntry() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 7, completedDays: Set(0..<7))
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(false)
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "Incomplete entry should return .none")
        }
    }
    
    // MARK: - Additional Total Completion Tests
    
    func testCompletionTotal100() throws {
        runAsyncTest {
            var completedDays = Set<Int>()
            for i in 0..<200 where i % 2 == 0 { // 100 completions
                completedDays.insert(i)
            }
            self.createEntrySequence(daysCount: 200, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionTotal100, "100 total completions should return .completionTotal100")
        }
    }
    
    func testCompletionTotal365() throws {
        runAsyncTest {
            var completedDays = Set<Int>()
            for i in 0..<730 where i % 2 == 0 { // 365 completions
                completedDays.insert(i)
            }
            self.createEntrySequence(daysCount: 730, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionTotal365, "365 total completions should return .completionTotal365")
        }
    }
    
    // MARK: - Edge Cases
    
    func testNoHistoricalData() throws {
        runAsyncTest {
            self.createEntrySequence(daysCount: 1, completedDays: [])
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "One day should return .none")
        }
    }
    
    func testSingleDayGap() throws {
        runAsyncTest {
            // Create entries with a single day gap
            var completedDays = Set<Int>()
            completedDays.insert(2) // Only one completion 2 days ago
            self.createEntrySequence(daysCount: 3, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .none, "Single day gap should not trigger renewal achievement")
        }
    }
    
    func testExactBoundaryConditions() throws {
        runAsyncTest {
            // Test exact boundary for renewed achievements
            var completedDays = Set<Int>()
            completedDays.insert(14) // Exactly 14 days ago
            self.createEntrySequence(daysCount: 15, completedDays: completedDays)
            
            guard let testEntry = self.getLatestEntry() else {
                XCTFail("Failed to fetch test entry")
                return
            }
            testEntry.setCompleted(true)
            testEntry.completionDates = [testEntry.date]
            
            let achievement = await self.modelData.completedEntry(entry: testEntry)
            XCTAssertEqual(achievement, .completionRenewed2, "Exactly 14 days should trigger .completionRenewed2")
        }
    }
}
