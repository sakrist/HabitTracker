//
//  ModelController.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 29/09/2024.
//

import SwiftData


@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let model = ModelData()
        modelContainer = model.modelContainer
        clearAllData()
        insertSampleData()
    }
    
    func isSampleDataPresent() -> Bool {
        // Use the ModelContext to check if any HabitItem already exists
        let fetchRequest = FetchDescriptor<HabitItem>() // Create a fetch descriptor
        
        do {
            // Fetch the items from the context
            let results = try context.fetch(fetchRequest)
            // Check if any HabitItem exists
            return !results.isEmpty
        } catch {
            print("Failed to check for existing sample data: \(error.localizedDescription)")
            return false
        }
    }
    
    func clearAllData() {
        let fetchRequest = FetchDescriptor<HabitItem>()
        let fetchRequestDaily = FetchDescriptor<DailyEntry>()
        
        do {
            // Fetch all HabitItems
            let habitItems = try context.fetch(fetchRequest)
            
            // Iterate over the fetched items and delete them from the context
            for habit in habitItems {
                context.delete(habit)
            }
            
            let dailyEntries = try context.fetch(fetchRequestDaily)
            
            for daily in dailyEntries {
                context.delete(daily)
            }

            // Save the context after deletion
            try context.save()
            print("All HabitItems have been deleted.")
            
        } catch {
            print("Failed to clear HabitItems: \(error.localizedDescription)")
        }
    }
    
    func insertSampleData() {
        if (isSampleDataPresent()) {
            return
        }
        var orderCount = 0
        for item in HabitItem.sampleData {
            item.order = orderCount
            context.insert(item)
            orderCount += 1
        }

        do {
            try context.save()
        } catch {
            print("Sample data context failed to save.")
        }
    }
}

