//
//  ModelData+fetch.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/01/2025.
//
import SwiftData
import Foundation


extension ModelData {
    
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
    
    func fetchCategories() -> [HabitCategory] {
        
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
        let c = fetchCategories()
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
    
    
    func calculateStreak(habit: HabitItem, for selectedMonth:Date, end: Date? = nil) -> (Int, Int, Int, Int) {
        
        let startDate = habit.timestamp.prevDay()
        let endDate = end ?? Date.endOfDay()
        
        var entries = fetchEntries(start: startDate, end: endDate, habit: habit, modelContext: modelContainer.mainContext)
        entries.sort { $0.date > $1.date }
        
        var streak:Int = 0
        var countStreak = true
        
        var longestStreak:Int = 0
        var currentStreak:Int = 0
        
        var completedInMonth:Int = 0
        var daysInMonth:Int = 0
        
        var total: Int = 0
        
        // remove first entry if it is today and not completed to make nice count
        if let firstEntry = entries.first {
            if (firstEntry.date.isToday() && !firstEntry.isCompleted) {
                entries.removeFirst()
            }
        }
        
        for item in entries {
            
            if countStreak && item.isCompleted {
                streak += 1
            } else {
                countStreak = false
            }
            
            if item.isCompleted {
                total += 1
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // If an entry is not completed, reset streak
                currentStreak = 0
            }
            
            if item.date.isSameMonth(date: selectedMonth) {
                daysInMonth += 1
                if item.isCompleted {
                    completedInMonth += 1
                }
            }
        }
        
        let rate:Int = daysInMonth > 0 ? Int((Double(completedInMonth) / Double(daysInMonth)) * 100.0) : 0
        
        return (streak, rate, longestStreak, total)
    }
}

// Load habit entries for the given date
func fetchHabitEntries(modelContext: ModelContext, for date: Date) -> [DailyEntry] {
    
    // Extract the weekday from the date
    let weekday = HabitItem.Weekday(date: date)
    
    // Query for existing entries
    let existingEntries = fetchEntries(for: date, modelContext: modelContext)
    
    // Check for and remove duplicates in existing entries before proceeding
    let dedupedExistingEntries = deduplicateEntries(existingEntries, modelContext: modelContext)
    
    let items = fetchHabits(modelContext: modelContext, predicate: #Predicate<HabitItem>{item in
        item.active
    })
    
    // Generate missing entries for the selected date
    var updatedEntries = generateDailyEntries(for: items, existingEntries: dedupedExistingEntries, date: date)

    // Save new entries in your data store if any are created
    for entry in updatedEntries where !dedupedExistingEntries.contains(entry) {
        modelContext.insert(entry)
    }
    
    do {
        updatedEntries = try updatedEntries.filter(#Predicate<DailyEntry>{ item in
            if let h = item.habit {
                h.active && h.weekdays.contains(weekday)
            } else {
                false
            }
        })
    } catch {
        print("Error fetchHabitEntries habits: \(error)")
    }
    // Final deduplication check before returning
    updatedEntries = deduplicateEntries(updatedEntries, modelContext: modelContext)
    
    updatedEntries = updatedEntries.sorted(by: sortDailyHabits)
    
    try? modelContext.save()
    return updatedEntries
}

// New function to deduplicate entries
func deduplicateEntries(_ entries: [DailyEntry], modelContext: ModelContext) -> [DailyEntry] {
    // Create a dictionary to track unique entries by habit ID + date
    var uniqueEntries: [String: DailyEntry] = [:]
    var duplicatesToDelete: [DailyEntry] = []
    
    for entry in entries {
        guard let habit = entry.habit else { continue }
        
        // Create a unique key from habit ID and date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)
        let key = "\(habit.id)_\(dateString)"
        
        if let existingEntry = uniqueEntries[key] {
            // Found a duplicate, decide which one to keep
            if entry.completionDates.count > existingEntry.completionDates.count {
                // Keep the entry with more completion data
                duplicatesToDelete.append(existingEntry)
                uniqueEntries[key] = entry
            } else {
                // Keep the existing entry
                duplicatesToDelete.append(entry)
            }
            
            print("⚠️ Found duplicate entry for habit \(habit.title) on \(dateString)")
        } else {
            // This is the first occurrence
            uniqueEntries[key] = entry
        }
    }
    
    // Delete the duplicates
    for duplicate in duplicatesToDelete {
        modelContext.delete(duplicate)
    }
    
    if !duplicatesToDelete.isEmpty {
        print("🔄 Removed \(duplicatesToDelete.count) duplicate entries")
        try? modelContext.save()
    }
    
    return Array(uniqueEntries.values)
}

// Generate daily entries for a specific date
func generateDailyEntries(for habits: [HabitItem], existingEntries: [DailyEntry], date: Date) -> [DailyEntry] {
    var dailyEntries = existingEntries
    
    for habit in habits {
        // skip deactivated
        if habit.isActive == false { continue }
        
        // Improved check for existing entries using both habit ID and date
        let existingEntry = dailyEntries.first { entry in
            guard let entryHabit = entry.habit else { return false }
            return entryHabit.id == habit.id && entry.date.isSameDay(as: date)
        }
        
        // If no entry exists for the selected date, create a new one
        if existingEntry == nil && habit.timestamp <= date {
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
    let endOfDay = startOfDay.nextDay()
    return fetchEntries(start: startOfDay, end: endOfDay, modelContext: modelContext)
}

// Fetch entries for a specific date
func fetchEntries(start: Date, end: Date, habit: HabitItem? = nil, modelContext: ModelContext) -> [DailyEntry] {
//    let calendar = Calendar.current
    // Create a predicate for fetching entries for the specific date
    
    var predicate: Predicate<DailyEntry>
    if let habitID = habit?.id {
        predicate = #Predicate { (entry: DailyEntry) in
            if let h = entry.habit {
                entry.date >= start && entry.date <= end && h.id == habitID
            } else {
                false
            }
        }
    } else {
        predicate = #Predicate { (entry: DailyEntry) in
            entry.date >= start && entry.date <= end
        }
    }

    // Perform the fetch using the modelContext
    let fetchDescriptor = FetchDescriptor<DailyEntry>(predicate: predicate)
    
    do {
        return try modelContext.fetch(fetchDescriptor)
    } catch {
        fatalError("Error fetching entries: \(error)")
    }
}


func fetchCategories(modelContext: ModelContext) -> [HabitCategory] {
    let fetchDescriptor = FetchDescriptor<HabitCategory>()
    do {
        return try modelContext.fetch(fetchDescriptor)
    } catch {
        fatalError("Error fetching categories: \(error)")
    }
}

// Add this function to fetch all entries
func fetchAllHabitEntries(modelContext: ModelContext) -> [DailyEntry] {
    let fetchDescriptor = FetchDescriptor<DailyEntry>()
    do {
        let entries = try modelContext.fetch(fetchDescriptor)
        return entries
    } catch {
        print("Error fetching all entries: \(error)")
        return []
    }
}
