//
//  ModelController.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 29/09/2024.
//

import SwiftData
import Foundation


@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let model = ModelData.shared
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
        let fetchRequestCategories = FetchDescriptor<HabitCategory>()
        
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
            
            // clear categories
            let categories = try context.fetch(fetchRequestCategories)
            for category in categories {
                context.delete(category)
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
        
        for item in HabitCategory.defaults {
            context.insert(item)
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

extension HabitItem {
    static let sampleData: [HabitItem] = [
        HabitItem(
            title: "Meditation",
            color: "#3498DB",
            category: HabitCategory.defaults[2],
            time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
            note: "5 minutes of meditation",
            weekdays: [.monday, .wednesday, .friday],
            order: 1
        ),
        HabitItem(
            title: "Running",
            color: "#E74C3C",
            category: HabitCategory.defaults[1],
            time: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()),
            note: "30 minutes of running",
            weekdays: [.tuesday, .thursday, .saturday],
            order: 2
        ),
        HabitItem(
            title: "Read a Book",
            color: "#9B59B6",
            category: HabitCategory.defaults[2],
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
            note: "Read for 30 minutes",
            weekdays: [.monday, .wednesday, .friday, .sunday],
            order: 3
        ),
        HabitItem(
            title: "Drink Water",
            color: "#1ABC9C",
            category: HabitCategory.defaults[0],
            time: nil,
            note: "8 glasses of water",
            weekdays: .init(Weekday.allCases),
            order: 4
        ),
        HabitItem(
            title: "Plan Tomorrow",
            color: "#F1C40F",
            category: HabitCategory.defaults[4],
            time: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
            note: "10 minutes to plan the next day",
            weekdays: .init(Weekday.allCases),
            order: 5
        ),
        HabitItem(
            title: "Stretch",
            color: "#2ECC71",
            category: HabitCategory.defaults[0],
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
            note: "5 minutes of stretching",
            weekdays: [.tuesday, .thursday, .saturday],
            order: 6
        ),
        HabitItem(
            title: "Write Journal",
            color: "#E67E22",
            category: HabitCategory.defaults[2],
            time: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()),
            note: "Reflect on the day",
            weekdays: [.sunday],
            order: 7
        )
    ]
}
