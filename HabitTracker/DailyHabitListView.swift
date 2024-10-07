//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 06/10/2024.
//

import Foundation
import SwiftUI
import SwiftData


struct DailyHabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var entries: [DailyEntry] = []
    @Query private var items: [HabitItem]
    
    @State private var selectedDate: Date = Date()  // The currently selected date

    var body: some View {
        NavigationSplitView {
            VStack {
                // Display the selected date
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                        loadHabitEntries(for: selectedDate)
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    
                    Spacer()
                    
                    Text(selectedDate, style: .date)  // Show the current selected date
                        .font(.headline)
                    
                    Spacer()
                    
                    if !isToday(selectedDate) {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                            loadHabitEntries(for: selectedDate)
                        }) {
                            Image(systemName: "arrow.right")
                        }
                    } else {
                        Image(systemName: "arrow.right").opacity(0)
                    }
                }
                .padding()

                List {
                    ForEach(entries) { entry in
                        if let habit = entry.habit {
                            HabitItemCell(item: habit, entry: entry)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Habits")
                .onAppear {
                    loadHabitEntries(for: selectedDate)
                    print("load entries")
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    // Load habit entries for the given date
    private func loadHabitEntries(for date: Date) {
        
        print("loadHabitEntries \(date)")
        
        // Query for existing entries
        let existingEntries = fetchEntries(for: date, modelContext: modelContext)

        // Generate missing entries for the selected date
        let updatedEntries = generateDailyEntries(for: items, existingEntries: existingEntries, date: date)

        // Save new entries in your data store if any are created
        for entry in updatedEntries where entry.habit != nil && !existingEntries.contains(entry) {
            modelContext.insert(entry)
        }
        entries = existingEntries
        try? modelContext.save()
    }
    
    // Generate daily entries for a specific date
    func generateDailyEntries(for habits: [HabitItem], existingEntries: [DailyEntry], date: Date) -> [DailyEntry] {
        var dailyEntries = existingEntries
        
        for habit in habits {
            // Check if we already have an entry for this habit on the selected date
            let existingEntry = dailyEntries.first { entry in
                entry.habit?.id == habit.id && isSameDay(entry.date, as: date)
            }
            
            // If no entry exists for the selected date, create a new one
            if existingEntry == nil {
                let newEntry = DailyEntry(title: nil, habit: habit, date: date, isCompleted: false)
                dailyEntries.append(newEntry)
            }
        }
        
        return dailyEntries
    }
    
    // Check if the selected date is today
    func isToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }

    // Helper function to compare dates by day
    func isSameDay(_ date1: Date, as date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
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
}

#Preview {
    DailyHabitListView()
        .modelContainer(SampleData.shared.modelContainer)
}
