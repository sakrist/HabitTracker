import XCTest
import SwiftData
@testable import HabitTracker

final class ModelDataFetchTests: XCTestCase {
    var modelData: ModelData!
    var mockContext: ModelContext!
    var testCategory: HabitCategory!
    
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
            
            testCategory = HabitCategory(id: "test", title: "Test Category", color: "#FFFFFF")
            mockContext.insert(testCategory)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
//    @MainActor func testInsertCategories() throws {
//        // Clear existing categories
//        try mockContext.delete(model: HabitCategory.self)
//        
//        modelData.insertCategories()
//        
//        let categories = try mockContext.fetch(FetchDescriptor<HabitCategory>())
//        XCTAssertFalse(categories.isEmpty)
//        XCTAssertTrue(categories.contains(where: { $0.id == "default" }))
//    }
    
    @MainActor func testFetchCategories() throws {
        let categories = modelData.fetchCategories()
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.first?.title ?? "" <= categories.last?.title ?? "")
    }
    
    @MainActor func testDefaultCategory() {
        let defaultCategory = modelData.defaultCategory()
        XCTAssertEqual(defaultCategory.id, "default")
        XCTAssertEqual(defaultCategory.title, "Other")
    }
    
    func testFetchHabitEntries() throws {
        // Create test habit
        let habit = HabitItem(title: "Test Habit", color: "#FF0000", category: testCategory)
        mockContext.insert(habit)
        
        let today = Date()
        let entries = fetchHabitEntries(modelContext: mockContext, for: today)
        
        XCTAssertNotNil(entries)
        XCTAssertTrue(entries.allSatisfy { $0.date.isSameDay(as: today) })
    }
    
    func testGenerateDailyEntries() {
        let habit1 = HabitItem(title: "Habit 1", color: "#FF0000", category: testCategory)
        let habit2 = HabitItem(title: "Habit 2", color: "#00FF00", category: testCategory)
        mockContext.insert(habit1)
        mockContext.insert(habit2)
        
        let today = Date()
        let existingEntries: [DailyEntry] = []
        let habits = [habit1, habit2]
        
        let generatedEntries = generateDailyEntries(for: habits, existingEntries: existingEntries, date: today)
        
        XCTAssertEqual(generatedEntries.count, 2)
        XCTAssertTrue(generatedEntries.allSatisfy { !$0.isCompleted })
    }
    
    func testFetchEntriesForDateRange() throws {
        let habit = HabitItem(title: "Test Habit", color: "#FF0000", category: testCategory)
        mockContext.insert(habit)
        
        let today = Date()
        let entry1 = DailyEntry(habit: habit, date: today, isCompleted: true)
        let entry2 = DailyEntry(habit: habit, date: today.addingTimeInterval(-86400), isCompleted: false)
        mockContext.insert(entry1)
        mockContext.insert(entry2)
        
        let startDate = today.addingTimeInterval(-172800) // 2 days ago
        let endDate = today
        
        let entries = fetchEntries(start: startDate, end: endDate, habit: habit, modelContext: mockContext)
        XCTAssertEqual(entries.count, 2)
    }
    
    func testFetchEntriesForSingleDate() throws {
        let habit = HabitItem(title: "Test Habit", color: "#FF0000", category: testCategory)
        mockContext.insert(habit)
        
        let today = Date()
        let entry = DailyEntry(habit: habit, date: today, isCompleted: true)
        mockContext.insert(entry)
        
        let entries = fetchEntries(for: today, modelContext: mockContext)
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries.first?.date.isSameDay(as: today) ?? false)
    }
    
    func testFetchHabits() throws {
        let habit1 = HabitItem(title: "Habit 1", color: "#FF0000", category: testCategory, order: 1)
        let habit2 = HabitItem(title: "Habit 2", color: "#00FF00", category: testCategory, order: 0)
        mockContext.insert(habit1)
        mockContext.insert(habit2)
        
        // Test fetching all habits
        let allHabits = fetchHabits(modelContext: mockContext)
        XCTAssertEqual(allHabits.count, 2)
        XCTAssertEqual(allHabits[0].title, "Habit 2") // Should be first due to order
        
        // Test fetching with predicate
        let activeHabits = fetchHabits(modelContext: mockContext, predicate: #Predicate<HabitItem> { $0.active })
        XCTAssertTrue(activeHabits.allSatisfy { $0.active })
    }
    
    func testGenerateDailyEntriesWithExisting() {
        let habit = HabitItem(title: "Test Habit", color: "#FF0000", category: testCategory)
        mockContext.insert(habit)
        
        let today = Date()
        let existingEntry = DailyEntry(habit: habit, date: today, isCompleted: true)
        let existingEntries = [existingEntry]
        
        let generatedEntries = generateDailyEntries(for: [habit], existingEntries: existingEntries, date: today)
        
        XCTAssertEqual(generatedEntries.count, 1)
        XCTAssertTrue(generatedEntries.first?.isCompleted ?? false)
    }
}
