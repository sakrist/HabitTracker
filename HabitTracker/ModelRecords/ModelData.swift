//
//  ModelContainer+extension.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/10/2024.
//

import SwiftData
import Foundation
import SwiftUI
import WidgetKit

@MainActor
@Observable class ModelData {
    static let shared = ModelData()
    
    var notificationsEnabled: Bool = false
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            HabitItem.self,
            HabitCategory.self,
            DailyEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        insertCategories()
    }
    
    func insertCategories() {
        let fetchRequestCategories = FetchDescriptor<HabitCategory>()
        do {
            let categories = try modelContainer.mainContext.fetch(fetchRequestCategories)
            if (categories.isEmpty) {
                for item in _defaultCategories() {
                    modelContainer.mainContext.insert(item)
                }
                try modelContainer.mainContext.save()
            }
        } catch {
            fatalError("Could not create Fetch Request: \(error)")
        }
    }
    
    func saveContext() {
        do {
            try modelContainer.mainContext.save()  // Explicitly save the changes to the modelContext
        } catch {
            print("Error saving model context: \(error)")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func defaultCategories() -> [HabitCategory] {
        
        let fetchRequestCategories = FetchDescriptor<HabitCategory>()
        do {
            let categories = try modelContainer.mainContext.fetch(fetchRequestCategories)
            if (!categories.isEmpty) {
                return categories.sorted { $0.title < $1.title }
            }
        } catch {
            fatalError("Error getting categories: \(error)")
        }
        return _defaultCategories()
    }
    
    public func defaultCategory() -> HabitCategory {
        let c = defaultCategories()
        for item in c {
            if (item.id == "default") {
                return item
            }
        }
        return HabitCategory(id: "default", title: "Other")
    }

    fileprivate func _defaultCategories() -> [HabitCategory]  {
        let categories = [
            HabitCategory(id: "health", title: "Health", color: "#FF5733"),     // Red-orange for health
            HabitCategory(id: "fitness", title: "Fitness", color: "#27AE60"),   // Green for fitness
            HabitCategory(id: "growth", title: "Growth", color: "#4CAF50"),     // Red-orange for health
            HabitCategory(id: "learning", title: "Learning", color: "#FF5733"), // Yellow for education
            HabitCategory(id: "productivity", title: "Productivity", color: "#1E88E5"), // blue for education
            HabitCategory(id: "hobbies", title: "Hobbies", color: "#8E44AD"),   // Purple for hobbies
            HabitCategory(id: "social", title: "Social", color: "#16A085"),    // Teal for social
            HabitCategory(id: "default", title: "Other")                                      // Default category
        ]
        return categories.sorted { $0.title < $1.title }
    }
}

// Load habit entries for the given date
func fetchHabitEntries(modelContext: ModelContext, for date: Date) -> [DailyEntry] {
    
    // Extract the weekday from the date
    let weekday = HabitItem.Weekday(date: date)
    
    // Query for existing entries
    let existingEntries = fetchEntries(for: date, modelContext: modelContext)
    
    let items = fetchHabits(modelContext: modelContext, predicate: #Predicate<HabitItem>{item in
        item.active
    })
    
    // Generate missing entries for the selected date
    var updatedEntries = generateDailyEntries(for: items, existingEntries: existingEntries, date: date)

    // Save new entries in your data store if any are created
    for entry in updatedEntries where !existingEntries.contains(entry) {
        modelContext.insert(entry)
    }
    do {
        updatedEntries = try updatedEntries.filter(#Predicate<DailyEntry>{ item in
            item.habit.active && item.habit.weekdays.contains(weekday)
        })
    } catch {
        print("Error fetchHabitEntries habits: \(error)")
    }
    updatedEntries = updatedEntries.sorted(by: sortDailyHabits)
    
    for item in updatedEntries {
        print("item \(item.habit.order) ")
    }
    
    try? modelContext.save()
    return updatedEntries
}

// Generate daily entries for a specific date
func generateDailyEntries(for habits: [HabitItem], existingEntries: [DailyEntry], date: Date) -> [DailyEntry] {
    var dailyEntries = existingEntries
    
    for habit in habits {
        // Check if we already have an entry for this habit on the selected date
        let existingEntry = dailyEntries.first { entry in
            entry.habit.id == habit.id && entry.date.isSameDay(as: date)
        }
        
        // If no entry exists for the selected date, create a new one
        if existingEntry == nil {
            let newEntry = DailyEntry(habit: habit, date: date, isCompleted: false)
            dailyEntries.append(newEntry)
        }
    }
    
    return dailyEntries
}

func fetchHabits(modelContext: ModelContext, predicate: Predicate<HabitItem>? = nil) -> [HabitItem] {
    
    let fetchDescriptor = FetchDescriptor<HabitItem>(predicate: predicate)
    do {
        var habits = try modelContext.fetch(fetchDescriptor)
        habits = habits.sorted { $0.order < $1.order }
        return habits
    } catch {
        fatalError("Error fetching active habits: \(error)")
    }
}

func fetchEntries(for date: Date, modelContext: ModelContext) -> [DailyEntry] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    return fetchEntries(start: startOfDay, end: endOfDay, modelContext: modelContext)
}

// Fetch entries for a specific date
func fetchEntries(start: Date, end: Date, habit: HabitItem? = nil, modelContext: ModelContext) -> [DailyEntry] {
//    let calendar = Calendar.current
    // Create a predicate for fetching entries for the specific date
    
    var predicate: Predicate<DailyEntry>
    if let habitID = habit?.id {
        predicate = #Predicate { (entry: DailyEntry) in
            entry.date >= start && entry.date < end && entry.habit.id == habitID
            }
    } else {
        predicate = #Predicate { (entry: DailyEntry) in
            entry.date >= start && entry.date < end
        }
    }

    // Perform the fetch using the modelContext
    let fetchDescriptor = FetchDescriptor<DailyEntry>(predicate: predicate)
    
    do {
        let entries = try modelContext.fetch(fetchDescriptor)
        print("fetchEntries \(entries)")
        return entries
    } catch {
        fatalError("Error fetching entries: \(error)")
    }
}



func fetchCategories(modelContext: ModelContext) -> [HabitCategory] {
    let fetchDescriptor = FetchDescriptor<HabitCategory>()
    do {
        let categories = try modelContext.fetch(fetchDescriptor)
        print("fetchCategories \(categories)")
        return categories
    } catch {
        fatalError("Error fetching categories: \(error)")
    }
}
