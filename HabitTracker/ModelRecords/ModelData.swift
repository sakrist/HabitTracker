//
//  ModelContainer+extension.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/10/2024.
//

import SwiftData
import Foundation
import SwiftUI

@Observable class ModelData {
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            HabitItem.self,
            DailyEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
    }
}
    
// Load habit entries for the given date
func fetchHabitEntries(modelContext: ModelContext, for date: Date) -> [DailyEntry] {
    
    
    // Query for existing entries
    let existingEntries = fetchEntries(for: date, modelContext: modelContext)
    
    let items = fetchHabits(modelContext: modelContext, predicate: #Predicate<HabitItem>{item in item.active })
    
    // Generate missing entries for the selected date
    var updatedEntries = generateDailyEntries(for: items, existingEntries: existingEntries, date: date)

    // Save new entries in your data store if any are created
    for entry in updatedEntries where !existingEntries.contains(entry) {
        modelContext.insert(entry)
    }
    do {
        updatedEntries = try updatedEntries.filter(#Predicate<DailyEntry>{ item in item.habit.active })
    } catch {
        
    }
    updatedEntries = updatedEntries.sorted { $0.habit.order < $1.habit.order }
    
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
        print("Error fetching active habits: \(error)")
    }
    return []
}

// Fetch entries for a specific date
private func fetchEntries(for date: Date, modelContext: ModelContext) -> [DailyEntry] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    print("fetchEntries \(startOfDay) to \(endOfDay)")
    // Create a predicate for fetching entries for the specific date
    let predicate = #Predicate { (entry: DailyEntry) in
        entry.date >= startOfDay && entry.date < endOfDay
    }

    // Perform the fetch using the modelContext
    let fetchDescriptor = FetchDescriptor<DailyEntry>(predicate: predicate)
    
    do {
        let entries = try modelContext.fetch(fetchDescriptor)
        print("fetchEntries \(entries)")
        return entries
    } catch {
        print("Error fetching entries: \(error)")
        return []
    }
}
