import XCTest
import SwiftData
@testable import HabitTracker

final class MigrationTests: XCTestCase {
    
//    @MainActor func testMigrationV3ToV4() throws {
//        // Create temp URL for test store
//        let storeURL = URL(fileURLWithPath: NSTemporaryDirectory())
//            .appendingPathComponent("TestStore")
//        
//        // Source configuration
//        let sourceSchema = Schema(versionedSchema: SchemaV3.self)
//        let configV3 = ModelConfiguration(schema: sourceSchema, url: storeURL)
//                
//        // Create and populate V3 container
//        let containerV3 = try ModelContainer(for: sourceSchema,
//                                             configurations: [configV3])
//        
//        // Create test data in V3 format
//        let context = containerV3.mainContext
//        let category = SchemaV3.HabitCategory(title: "Test", color: "#FF0000")
//        let habit = SchemaV3.HabitItem(title: "Test Habit", category: category)
//        let entry1 = SchemaV3.DailyEntry(habit: habit, date: Date(), isCompleted: true, completionDate: Date())
//        let entry2 = SchemaV3.DailyEntry(habit: habit, date: Date(), isCompleted: false)
//        
//        context.insert(category)
//        context.insert(habit)
//        context.insert(entry1)
//        context.insert(entry2)
//        
//        // Important: Save and destroy the source container
//        try context.save()
//        
//        // Target configuration - must use same URL
//        let targetSchema = Schema(versionedSchema: SchemaV4.self)
//        let configV4 = ModelConfiguration(schema: targetSchema,
//                                          url: storeURL)
//        
//        // Perform migration
//        let migratedContainer = try ModelContainer(
//            for: targetSchema,
//            migrationPlan: MigrationPlanToLatest.self,
//            configurations: [configV4]
//        )
//        
//        // Verify migration results
//        let migratedContext = migratedContainer.mainContext
//        
//        // Test habits migration
//        let habits = try migratedContext.fetch(FetchDescriptor<SchemaV4.HabitItem>())
//        XCTAssertEqual(habits.count, 1)
//        XCTAssertEqual(habits[0].targetCount, 1)
//        
//        // Test entries migration
//        let entries = try migratedContext.fetch(FetchDescriptor<SchemaV4.DailyEntry>())
//        XCTAssertEqual(entries.count, 2)
//        
//        let completedEntry = entries.first { $0.isCompleted }
//        XCTAssertNotNil(completedEntry)
//        XCTAssertEqual(completedEntry?.completionDates.count, 1)
//        XCTAssertEqual(completedEntry?.achievement, Achievement.none)
//        
//        let incompletedEntry = entries.first { !$0.isCompleted }
//        XCTAssertNotNil(incompletedEntry)
//        XCTAssertTrue(incompletedEntry?.completionDates.isEmpty ?? false)
//        XCTAssertEqual(incompletedEntry?.achievement, Achievement.none)
//    }
    
//    override func tearDown() {
//        super.tearDown()
//        // Clean up test store
//        try? FileManager.default.removeItem(at: URL(fileURLWithPath: NSTemporaryDirectory())
//            .appendingPathComponent("TestStore"))
//    }
}
