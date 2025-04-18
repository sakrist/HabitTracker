import XCTest
import SwiftData
@testable import HabitTracker

final class StreakTests: XCTestCase {
    var modelData: ModelData!
    var mockContext: ModelContext!
    var testHabit: HabitItem!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let expectation = XCTestExpectation(description: "Setup completed")
        
        Task { @MainActor in
            let schema = Schema(versionedSchema: SchemaLatest.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            modelData = ModelData()
            modelData.modelContainer = container
            mockContext = container.mainContext
            
            let testCategory = HabitCategory(id: "test", title: "Test Category")
            mockContext.insert(testCategory)
            
            testHabit = HabitItem(
                title: "Test Habit",
                color: "#FF0000",
                category: testCategory,
                timestamp: Date().addingTimeInterval(-400 * 86400)
            )
            mockContext.insert(testHabit)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func createEntries(completedDays: Set<Int>, startDate: Date = Date()) {
        try? mockContext.delete(model: DailyEntry.self)
        
        let calendar = Calendar.current
        for i in 0..<30 {
            let entryDate = calendar.date(byAdding: .day, value: -i, to: startDate)!
            let entry = DailyEntry(
                habit: testHabit,
                date: entryDate
            )
            entry.setCompleted(completedDays.contains(i))
            mockContext.insert(entry)
        }
        try? mockContext.save()
    }
    
    @MainActor func testCurrentStreak() {
        // Test current streak with 5 consecutive completed days
        createEntries(completedDays: Set(0..<5))
        let (streak, _, _, _) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(streak, 5)
    }
    
    @MainActor func testBrokenStreak() {
        // Create entries with a break in the streak
        var completedDays = Set(0..<7)
        completedDays.remove(2) // Break on day 3
        createEntries(completedDays: completedDays)
        
        let (streak, _, _, _) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(streak, 2) // Only counts the most recent consecutive completions
    }
    
    @MainActor func testLongestStreak() {
        // Create pattern with multiple streaks
        var completedDays = Set<Int>()
        // First streak: 5 days
        completedDays.formUnion(Set(10..<15))
        // Second streak: 6 days
        completedDays.formUnion(Set(3..<9))
        // Current streak: 2 days
        completedDays.formUnion(Set(0..<2))
        
        createEntries(completedDays: completedDays)
        let (_, _, longest, _) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(longest, 6)
    }
    
    @MainActor func testMonthlyRate() {
        
        let calendar = Calendar.current
        // april 2025 start of month
        let startOfMonth = calendar.date(from: DateComponents(year: 2024, month: 4, day: 2))!
        let endOfMonth = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1))!
        // Create 15 completed days in a 30-day month
        var completedDays = Set<Int>()
        for i in 0..<30 where i % 2 == 0 {
            completedDays.insert(i)
        }
        
        createEntries(completedDays: completedDays, startDate: startOfMonth)
        let (_, rate, _, _) = modelData.calculateStreak(habit: testHabit, for: startOfMonth, end: endOfMonth)
        XCTAssertEqual(rate, 50) // 50% completion rate
    }
    
    @MainActor func testTotalCompletions() {
        // Create pattern with 20 total completions
        var completedDays = Set<Int>()
        for i in 0..<30 where i % 3 == 0 {
            completedDays.insert(i)
        }
        
        createEntries(completedDays: completedDays)
        let (_, _, _, total) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(total, 10) // Every third day completed
    }
    
    @MainActor func testNoCompletions() {
        createEntries(completedDays: [])
        let (streak, rate, longest, total) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(streak, 0)
        XCTAssertEqual(rate, 0)
        XCTAssertEqual(longest, 0)
        XCTAssertEqual(total, 0)
    }
    
    @MainActor func testAllCompletions() {
        createEntries(completedDays: Set(0..<30))
        let (streak, rate, longest, total) = modelData.calculateStreak(habit: testHabit, for: Date())
        XCTAssertEqual(streak, 30)
        XCTAssertEqual(rate, 100)
        XCTAssertEqual(longest, 30)
        XCTAssertEqual(total, 30)
    }
}
