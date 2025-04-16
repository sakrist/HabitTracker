//
//  ExportImportTests.swift
//  HabitTrackerTests
//
//  Created by Volodymyr Boichentsov on 17/04/2025.
//

import XCTest
import SwiftData
@testable import HabitTracker

final class ExportImportTests: XCTestCase {
    
    var modelData: ModelData!
    var mockContext: ModelContext!
    var testCategory: HabitCategory!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Set up test environment asynchronously
        let expectation = XCTestExpectation(description: "Setup completed")
        
        Task { @MainActor in
            // Set up in-memory container for testing
            let schema = Schema(versionedSchema: SchemaLatest.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            modelData = ModelData(container: container)
            mockContext = container.mainContext
            
            // Create a test category
            testCategory = HabitCategory(id: "test_category", title: "Test Category", color: "#FFFFFF")
            mockContext.insert(testCategory)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
        modelData = nil
        testCategory = nil
        try super.tearDownWithError()
    }
    
    // Helper method to run async tasks in tests
    func runAsyncTest(testBlock: @escaping () async -> Void) {
        let expectation = XCTestExpectation(description: "Async test")
        Task { @MainActor in
            await testBlock()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Test Data Setup
    
    @MainActor
    func createTestHabits() async -> [HabitItem] {
        // Clear existing data first to ensure a clean test environment
        try? mockContext.delete(model: HabitItem.self)
        try? mockContext.delete(model: DailyEntry.self)
        try? mockContext.save()
        
        // Create habits
        let habit1 = HabitItem(
            id: "test_habit_1",
            title: "Morning Run",
            color: "#FF0000",
            category: testCategory,
            note: "Daily running",
            weekdays: [.monday, .wednesday, .friday],
            order: 0,
            timestamp: Date().addingTimeInterval(-86400 * 30) // 30 days ago
        )
        
        let habit2 = HabitItem(
            id: "test_habit_2",
            title: "Meditation",
            color: "#00FF00",
            category: testCategory,
            note: "Mindfulness practice",
            weekdays: [.tuesday, .thursday, .saturday, .sunday],
            order: 1,
            timestamp: Date().addingTimeInterval(-86400 * 15) // 15 days ago
        )
        
        mockContext.insert(habit1)
        mockContext.insert(habit2)
        
        // Create entries for habit1
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let entry1 = DailyEntry(habit: habit1, date: today, isCompleted: true, completionDate: today)
        let entry2 = DailyEntry(habit: habit1, date: yesterday, isCompleted: false)
        
        mockContext.insert(entry1)
        mockContext.insert(entry2)
        
        // Create entries for habit2
        let entry3 = DailyEntry(habit: habit2, date: today, isCompleted: true, completionDate: today)
        let entry4 = DailyEntry(habit: habit2, date: yesterday, isCompleted: true, completionDate: yesterday)
        
        mockContext.insert(entry3)
        mockContext.insert(entry4)
        
        try? mockContext.save()
        
        return [habit1, habit2]
    }
    
    // MARK: - Export Tests
    
    func testExportHabits() throws {
        runAsyncTest {
            // Create test data in a clean environment
            _ = await self.createTestHabits()
            
            // Create an instance of ExportImportData with our test context
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            // Export habits
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Print exported JSON for review
            do {
                let exportedData = try Data(contentsOf: exportURL)
                if let jsonString = String(data: exportedData, encoding: .utf8) {
                    print("\n=== Exported JSON ===\n\(jsonString)\n=====================")
                }
            } catch {
                print("Failed to read exported JSON: \(error)")
            }
            
            // Read the exported data and verify content
            do {
                let exportedData = try Data(contentsOf: exportURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let exportedHabits = try decoder.decode(ExportData.self, from: exportedData)
                
                // Verify habits count
                XCTAssertEqual(exportedHabits.habits.count, 2, "Should export 2 habits")
                
                // Verify habit details
                let habit1 = exportedHabits.habits.first { $0.id == "test_habit_1" }
                XCTAssertNotNil(habit1, "First habit should be exported")
                XCTAssertEqual(habit1?.title, "Morning Run")
                XCTAssertEqual(habit1?.completions.count, 2, "First habit should have 2 entries")
                
                let habit2 = exportedHabits.habits.first { $0.id == "test_habit_2" }
                XCTAssertNotNil(habit2, "Second habit should be exported")
                XCTAssertEqual(habit2?.title, "Meditation")
                XCTAssertEqual(habit2?.completions.count, 2, "Second habit should have 2 entries")
                
                // Verify completion details
                let habit1Completions = habit1?.completions ?? []
                XCTAssertEqual(habit1Completions.filter { $0.completed }.count, 1, "First habit should have 1 completed entry")
                
                let habit2Completions = habit2?.completions ?? []
                XCTAssertEqual(habit2Completions.filter { $0.completed }.count, 2, "Second habit should have 2 completed entries")
                
            } catch {
                XCTFail("Failed to read or parse exported data: \(error)")
            }
        }
    }
    
    func testExportEmptyDatabase() throws {
        runAsyncTest {
            // Clear any existing data
            try? self.mockContext.delete(model: HabitItem.self)
            try? self.mockContext.delete(model: DailyEntry.self)
            try? self.mockContext.save()
            
            // Don't create any habits, export with empty database
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Read the exported data and verify content
            do {
                let exportedData = try Data(contentsOf: exportURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let exportedHabits = try decoder.decode(ExportData.self, from: exportedData)
                
                // Should export an empty array of habits
                XCTAssertEqual(exportedHabits.habits.count, 0, "Should export 0 habits")
                
            } catch {
                XCTFail("Failed to read or parse exported data: \(error)")
            }
        }
    }
    
    func testExportSkipsInactiveHabits() throws {
        runAsyncTest {
            // Create test data with one active and one inactive habit
            let habits = await self.createTestHabits()
            
            // Make the second habit inactive
            habits[1].active = false
            try? self.mockContext.save()
            
            // Export habits
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Verify exported data
            do {
                let exportedData = try Data(contentsOf: exportURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let exportedHabits = try decoder.decode(ExportData.self, from: exportedData)
                
                // Should only export the active habit
                XCTAssertEqual(exportedHabits.habits.count, 1, "Should only export active habits")
                XCTAssertEqual(exportedHabits.habits[0].id, "test_habit_1", "Exported habit should be the active one")
            } catch {
                XCTFail("Failed to read or parse exported data: \(error)")
            }
        }
    }
    
    // MARK: - Import Tests
    
    func testImportHabits() throws {
        runAsyncTest {
            // Create and export test data
            let _ = await self.createTestHabits()
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Clear database
            try? self.mockContext.delete(model: HabitItem.self)
            try? self.mockContext.delete(model: DailyEntry.self)
            try? self.mockContext.save()
            
            // Verify database is empty
            let habitsFetchDescriptor = FetchDescriptor<HabitItem>()
            let entriesFetchDescriptor = FetchDescriptor<DailyEntry>()
            
            let habitsBeforeImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            XCTAssertEqual(habitsBeforeImport?.count, 0, "Database should be empty before import")
            
            // Import the previously exported data
            let importSuccess = await exportImport.importHabits(from: exportURL)
            XCTAssertTrue(importSuccess, "Import should succeed")
            
            // Verify imported data
            let habitsAfterImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            XCTAssertEqual(habitsAfterImport?.count, 2, "Should import 2 habits")
            
            let entriesAfterImport = try? self.mockContext.fetch(entriesFetchDescriptor)
            XCTAssertEqual(entriesAfterImport?.count, 4, "Should import 4 entries")
            
            // Verify habit details
            let importedHabit1 = habitsAfterImport?.first { $0.id == "test_habit_1" }
            XCTAssertNotNil(importedHabit1, "First habit should be imported")
            XCTAssertEqual(importedHabit1?.title, "Morning Run")
            
            let importedHabit2 = habitsAfterImport?.first { $0.id == "test_habit_2" }
            XCTAssertNotNil(importedHabit2, "Second habit should be imported")
            XCTAssertEqual(importedHabit2?.title, "Meditation")
            
            // Verify entry counts
            let habit1Entries = entriesAfterImport?.filter { $0.habit.id == "test_habit_1" } ?? []
            XCTAssertEqual(habit1Entries.count, 2, "First habit should have 2 entries")
            
            let habit2Entries = entriesAfterImport?.filter { $0.habit.id == "test_habit_2" } ?? []
            XCTAssertEqual(habit2Entries.count, 2, "Second habit should have 2 entries")
            
            // Verify completion status
            let habit1CompletedEntries = habit1Entries.filter { $0.isCompleted }
            XCTAssertEqual(habit1CompletedEntries.count, 1, "First habit should have 1 completed entry")
            
            let habit2CompletedEntries = habit2Entries.filter { $0.isCompleted }
            XCTAssertEqual(habit2CompletedEntries.count, 2, "Second habit should have 2 completed entries")
        }
    }
    
    func testImportWithExistingData() throws {
        runAsyncTest {
            // Create initial test data
            await self.createTestHabits()
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Modify database (update existing habit and add new one)
            let habitsFetchDescriptor = FetchDescriptor<HabitItem>()
            let existingHabits = try? self.mockContext.fetch(habitsFetchDescriptor)
            
            if let habit1 = existingHabits?.first(where: { $0.id == "test_habit_1" }) {
                habit1.title = "Evening Run" // Change the title
            }
            
            // Add a new habit
            let newHabit = HabitItem(
                id: "test_habit_3",
                title: "New Habit",
                color: "#0000FF",
                category: self.testCategory,
                order: 2
            )
            self.mockContext.insert(newHabit)
            
            try? self.mockContext.save()
            
            // Import the previously exported data (should override existing)
            let importSuccess = await exportImport.importHabits(from: exportURL)
            XCTAssertTrue(importSuccess, "Import should succeed")
            
            // Verify imported data
            let habitsAfterImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            
            // Should have all three habits
            XCTAssertEqual(habitsAfterImport?.count, 3, "Should have 3 habits after import")
            
            // Verify habit1 was reset to original name from export
            let importedHabit1 = habitsAfterImport?.first { $0.id == "test_habit_1" }
            XCTAssertEqual(importedHabit1?.title, "Morning Run", "Habit 1 should be reset to original name")
            
            // Verify habit3 still exists (wasn't in export)
            let habit3 = habitsAfterImport?.first { $0.id == "test_habit_3" }
            XCTAssertNotNil(habit3, "New habit should still exist")
        }
    }
    
    func testImportInvalidFile() throws {
        runAsyncTest {
            // Create invalid JSON data
            let invalidData = """
            {
                "habits": [
                    {
                        "id": "invalid_habit",
                        "title": "Invalid Habit"
                        // Missing closing bracket and other required fields
            """.data(using: .utf8)!
            
            // Create a temporary file
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let invalidFileURL = temporaryDirectoryURL.appendingPathComponent("invalid_export.json")
            
            do {
                try invalidData.write(to: invalidFileURL)
            } catch {
                XCTFail("Failed to create invalid test file: \(error)")
                return
            }
            
            // Try to import the invalid file
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            let importSuccess = await exportImport.importHabits(from: invalidFileURL)
            
            // Import should fail
            XCTAssertFalse(importSuccess, "Import of invalid data should fail")
        }
    }
    
    func testImportSetsHabitsToActive() throws {
        runAsyncTest {
            // Create and export test data
            let habits = await self.createTestHabits()
            
            // Export habits
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Deactivate a habit
            habits[0].active = false
            try? self.mockContext.save()
            
            // Import the previously exported data
            let importSuccess = await exportImport.importHabits(from: exportURL)
            XCTAssertTrue(importSuccess, "Import should succeed")
            
            // Verify that all imported habits are active
            let habitsFetchDescriptor = FetchDescriptor<HabitItem>()
            let habitsAfterImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            
            // Check that habit1 is now active again
            let importedHabit1 = habitsAfterImport?.first { $0.id == "test_habit_1" }
            XCTAssertTrue(importedHabit1?.active ?? false, "Imported habit should be set to active")
        }
    }
    
    func testRepeatedImport() throws {
        runAsyncTest {
            // Create initial test data with duplicate check
            let habits = await self.createTestHabits()
            
            // Set some test values for new fields
            habits[0].time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
            habits[0].hType = "test_type_1"
            habits[1].time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
            habits[1].hType = "test_type_2"
            try? self.mockContext.save()
            
            // Export habits
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            guard let exportURL = await exportImport.exportHabits() else {
                XCTFail("Failed to export habits")
                return
            }
            
            // Get initial counts
            let habitsFetchDescriptor = FetchDescriptor<HabitItem>()
            let entriesFetchDescriptor = FetchDescriptor<DailyEntry>()
            
            // Multiple imports
            for _ in 1...3 { // Try importing 3 times
                let importSuccess = await exportImport.importHabits(from: exportURL)
                XCTAssertTrue(importSuccess, "Import should succeed")
                
                // After each import, verify no duplicates
                let habitsAfterImport = try? self.mockContext.fetch(habitsFetchDescriptor)
                let entriesAfterImport = try? self.mockContext.fetch(entriesFetchDescriptor)
                
                // Check for duplicates by ID
                let habitIds = habitsAfterImport?.map { $0.id }
                let uniqueHabitIds = Set(habitIds ?? [])
                XCTAssertEqual(habitIds?.count, uniqueHabitIds.count, "Should have no duplicate habits")
                XCTAssertEqual(uniqueHabitIds.count, 2, "Should maintain exactly 2 habits")
                
                // Check each habit has exactly the expected number of entries
                let habit1Entries = entriesAfterImport?.filter { $0.habit.id == "test_habit_1" }
                let habit2Entries = entriesAfterImport?.filter { $0.habit.id == "test_habit_2" }
                
                XCTAssertEqual(habit1Entries?.count, 2, "First habit should have exactly 2 entries")
                XCTAssertEqual(habit2Entries?.count, 2, "Second habit should have exactly 2 entries")
                
                // Verify properties are preserved
                let habit1 = habitsAfterImport?.first { $0.id == "test_habit_1" }
                let habit2 = habitsAfterImport?.first { $0.id == "test_habit_2" }
                
                XCTAssertEqual(habit1?.hType, "test_type_1", "First habit should preserve hType")
                XCTAssertEqual(habit2?.hType, "test_type_2", "Second habit should preserve hType")
                XCTAssertNotNil(habit1?.time, "First habit should preserve time")
                XCTAssertNotNil(habit2?.time, "Second habit should preserve time")
            }
        }
    }
    
    func testImportFromFixedFile() throws {
        runAsyncTest {
            // Clear database before first import
            try? self.mockContext.delete(model: HabitItem.self)
            try? self.mockContext.delete(model: DailyEntry.self)
            try? self.mockContext.save()
            
            let exportImport = await ExportImportData()
            await exportImport.setModelContext(self.mockContext)
            
            // Get the URL for the bundled JSON file
            guard let fileURL = Bundle(for: type(of: self)).url(forResource: "HabitTracker_Export", withExtension: "json") else {
                XCTFail("Could not find HabitTracker_Export.json")
                return
            }
            
            // First import
            let importSuccess1 = await exportImport.importHabits(from: fileURL)
            XCTAssertTrue(importSuccess1, "First import should succeed")
            
            // Check counts after first import
            let habitsFetchDescriptor = FetchDescriptor<HabitItem>()
            let entriesFetchDescriptor = FetchDescriptor<DailyEntry>()
            
            let habitsAfterFirstImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            let entriesAfterFirstImport = try? self.mockContext.fetch(entriesFetchDescriptor)
            
            let firstImportHabitCount = habitsAfterFirstImport?.count ?? 0
            let firstImportEntriesCount = entriesAfterFirstImport?.count ?? 0
            
            XCTAssertGreaterThan(firstImportHabitCount, 0, "Should have imported habits")
            
            // Second import of the same file
            let importSuccess2 = await exportImport.importHabits(from: fileURL)
            XCTAssertTrue(importSuccess2, "Second import should succeed")
            
            // Verify no duplicates after second import
            let habitsAfterSecondImport = try? self.mockContext.fetch(habitsFetchDescriptor)
            let entriesAfterSecondImport = try? self.mockContext.fetch(entriesFetchDescriptor)
            
            XCTAssertEqual(habitsAfterSecondImport?.count, firstImportHabitCount, "Should have same number of habits after second import")
            XCTAssertEqual(entriesAfterSecondImport?.count, firstImportEntriesCount, "Should have same number of entries after second import")
            
            // Verify habits have unique IDs
            let habitIds = habitsAfterSecondImport?.map { $0.id }
            let uniqueHabitIds = Set(habitIds ?? [])
            XCTAssertEqual(habitIds?.count, uniqueHabitIds.count, "Should have no duplicate habit IDs")
            
            // Print a summary of what was imported
            if let habits = habitsAfterSecondImport {
                print("\n=== Import Summary ===")
                print("Total habits: \(habits.count)")
                for habit in habits {
                    print("Habit: \(habit.title) (ID: \(habit.id))")
                    let habitEntries = entriesAfterSecondImport?.filter { $0.habit.id == habit.id }
                    print("  Entries: \(habitEntries?.count ?? 0)")
                }
                print("===================\n")
            }
        }
    }
}
