//
//  ExportImportData.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 16/04/2025.
//

import Foundation
import SwiftData
import SwiftUI

// Struct to represent exportable habit data
struct ExportableHabit: Codable {
    var id: String
    var title: String
    var color: String
    var categoryId: String
    var categoryTitle: String
    var note: String
    var weekdays: [Int]
    var order: Int
    var timestamp: Date
    var completions: [CompletionRecord]
    var time: Date?
    var hType: String?
    var targetCount: Int?
    
    struct CompletionRecord: Codable {
        var date: Date
        var completed: Bool
        var completionDates: [Date]?
        var achievement: Int?
    }
}

struct ExportData: Codable {
    var habits: [ExportableHabit]
    var exportDate: Date
    var version: Int = 1
}

@MainActor
class ExportImportData {
    static let shared = ExportImportData()
    
    // Allow setting custom model context for testing
    private(set) var modelContext: ModelContext
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? ModelData.shared.modelContainer.mainContext
    }
    
    // Method to allow changing modelContext safely from tests
    @MainActor
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func exportHabits() -> URL? {
        // Use the injected modelContext instead of always using shared
        
        // Fetch all active habits only
        let habitsFetchDescriptor = FetchDescriptor<HabitItem>(
            predicate: #Predicate<HabitItem> { item in item.active }
        )
        
        guard let habits = try? modelContext.fetch(habitsFetchDescriptor) else {
            print("Failed to fetch habits")
            return nil
        }
        
        var exportableHabits: [ExportableHabit] = []
        
        // For each habit, fetch its entries and create exportable data
        for habit in habits {
            // Fetch all entries for this habit
            let entriesPredicate = #Predicate<DailyEntry> { entry in
                if let h = entry.habit {
                    h.id == habit.id
                } else {
                    false
                }
            }
            let entriesFetchDescriptor = FetchDescriptor<DailyEntry>(predicate: entriesPredicate)
            
            guard let entries = try? modelContext.fetch(entriesFetchDescriptor) else {
                print("Failed to fetch entries for habit: \(habit.title)")
                continue
            }
            
            // Create completion records
            let completions = entries.map { entry in
                ExportableHabit.CompletionRecord(
                    date: entry.date,
                    completed: entry.isCompleted,
                    completionDates: entry.completionDates,
                    achievement: entry.achievement?.rawValue ?? 0
                )
            }
            
            // Create exportable habit
            let exportableHabit = ExportableHabit(
                id: habit.id,
                title: habit.title,
                color: habit.color,
                categoryId: habit.category?.id ?? "default",
                categoryTitle: habit.category?.title ?? "Other",
                note: habit.note,
                weekdays: habit.weekdays.map { $0.rawValue },
                order: habit.order,
                timestamp: habit.timestamp,
                completions: completions,
                time: habit.time,
                hType: habit.hType,
                targetCount: habit.targetCount
            )
            
            exportableHabits.append(exportableHabit)
        }
        
        // Create the export data container
        let exportData = ExportData(
            habits: exportableHabits,
            exportDate: Date()
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let jsonData = try? encoder.encode(exportData) else {
            print("Failed to encode export data")
            return nil
        }
        
        // Create a temporary file
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("HabitTracker_Export_\(Date().ISO8601Format()).json")
        
        do {
            try jsonData.write(to: temporaryFileURL)
            return temporaryFileURL
        } catch {
            print("Failed to write export data: \(error)")
            return nil
        }
    }
    
    func importHabits(from url: URL) async -> Bool {
        do {
            // Read the file data
            let data = try Data(contentsOf: url)
            
            // Decode the JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedData = try decoder.decode(ExportData.self, from: data)
            

            modelContext.undoManager = nil
            
            // Process each imported habit
            var importedHabits: [HabitItem] = []
            
            for importedHabit in importedData.habits {
                // Check if habit already exists
                let habitPredicate = #Predicate<HabitItem> { item in
                    item.id == importedHabit.id
                }
                let habitFetchDescriptor = FetchDescriptor<HabitItem>(predicate: habitPredicate)
                let existingHabits = try modelContext.fetch(habitFetchDescriptor)
                
                // If habit exists, update it, otherwise create new
                let habit: HabitItem
                if let existingHabit = existingHabits.first {
                    habit = existingHabit
                    // Update properties
                    habit.title = importedHabit.title
                    habit.color = importedHabit.color
                    habit.note = importedHabit.note
                    habit.order = importedHabit.order
                    habit.timestamp = importedHabit.timestamp
                    habit.active = true  // Set habit to active on import
                    habit.time = importedHabit.time
                    habit.hType = importedHabit.hType
                    habit.targetCount = importedHabit.targetCount ?? 1
                    
                    // Convert weekdays
                    var weekdays = Set<HabitItem.Weekday>()
                    for rawValue in importedHabit.weekdays {
                        if let weekday = HabitItem.Weekday(rawValue: rawValue) {
                            weekdays.insert(weekday)
                        }
                    }
                    habit.weekdays = weekdays
                    
                    // Delete existing entries to avoid duplicates
                    let entryPredicate = #Predicate<DailyEntry> { entry in
                        if let h = entry.habit {
                            h.id == habit.id
                        } else {
                            false
                        }
                    }
                    try modelContext.delete(model: DailyEntry.self, where: entryPredicate)
                } else {
                    // Find or create category
                    let categoryPredicate = #Predicate<HabitCategory> { category in
                        category.id == importedHabit.categoryId
                    }
                    let categoryFetchDescriptor = FetchDescriptor<HabitCategory>(predicate: categoryPredicate)
                    let existingCategories = try modelContext.fetch(categoryFetchDescriptor)
                    
                    let category: HabitCategory
                    if let existingCategory = existingCategories.first {
                        category = existingCategory
                    } else {
                        // Create the category
                        category = HabitCategory(
                            id: importedHabit.categoryId,
                            title: importedHabit.categoryTitle
                        )
                        modelContext.insert(category)
                    }
                    
                    // Convert weekdays
                    var weekdays = Set<HabitItem.Weekday>()
                    for rawValue in importedHabit.weekdays {
                        if let weekday = HabitItem.Weekday(rawValue: rawValue) {
                            weekdays.insert(weekday)
                        }
                    }
                    
                    // Create the habit
                    habit = HabitItem(
                        id: importedHabit.id,
                        title: importedHabit.title,
                        color: importedHabit.color,
                        category: category,
                        time: importedHabit.time,
                        note: importedHabit.note,
                        weekdays: weekdays,
                        order: importedHabit.order,
                        timestamp: importedHabit.timestamp,
                        active: true  // Ensure the habit is active
                    )
                    habit.targetCount = importedHabit.targetCount ?? 1
                    habit.hType = importedHabit.hType
                    modelContext.insert(habit)
                }
                
                // Create entries
                for completion in importedHabit.completions {
                    let entry = DailyEntry(
                        habit: habit,
                        date: completion.date,
                        isCompleted: completion.completed
                    )
                    entry.completionDates = completion.completionDates ?? []
                    entry.achievement =  Achievement(rawValue: completion.achievement ?? 0)
                    modelContext.insert(entry)
                }
                
                // Add the habit to our tracking array
                importedHabits.append(habit)
            }
            
            // Save changes
            try modelContext.save()
            
            // Request Health authorizations for any habits with health tracking
            await requestHealthPermissions(for: importedHabits)
            
            
            modelContext.undoManager = ModelData.undoManager
            
            return true
        } catch {
            print("Failed to import habits: \(error)")
            return false
        }
    }
    
    private func requestHealthPermissions(for habits: [HabitItem]) async {
        // Filter for habits with health integrations
        let healthHabits = habits.filter { 
            $0.healthType != nil && $0.healthType != .none 
        }
        
        if !healthHabits.isEmpty {
            // Request health permissions for all health types at once
            await withCheckedContinuation { continuation in
                Health.shared.requestBulkHealthAuthorization(for: healthHabits) { success in
                    if success {
                        print("Successfully authorized health access for imported habits")
                    } else {
                        print("Failed to authorize some health types for imported habits")
                    }
                    
                    // Set up background delivery for authorized habits
                    Task {
                        for habit in healthHabits {
                            if Health.shared.verifyHealthAuthorization(for: habit) {
                                Health.shared.enableHabitBackgroundDelivery(habit: habit) { _ in }
                            }
                        }
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    // New method to replace all data with imported data
    func replaceAllWithImport(from url: URL) async -> Bool {
        do {
            // Start by deleting all existing data
            await deleteAllData()
            
            // Then import the new data
            return await importHabits(from: url)
        } catch {
            print("Failed to replace data: \(error)")
            return false
        }
    }
    
    // Helper method to delete all data
    private func deleteAllData() async {
        do {
            // Delete all entries first (due to relationships)
            try modelContext.delete(model: DailyEntry.self)
            
            // Delete all habits
            try modelContext.delete(model: HabitItem.self)
            
            // Note: We're not deleting categories since they may be system defaults
            // If you want to delete categories too, uncomment:
            // try modelContext.delete(model: HabitCategory.self)
            // Then re-create default categories
            // ModelData.shared.insertCategories()
            
            try modelContext.save()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
    
    // Adding a convenience method to expose this functionality
    func clearAllData() async -> Bool {
        do {
            await deleteAllData()
            return true
        } catch {
            print("Failed to clear data: \(error)")
            return false
        }
    }
}
