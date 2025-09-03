//
//  ContentView.swift
//  HabitTrackerWatch Watch App
//
//  Created by Volodymyr Boichentsov on 16/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    var body: some View {
        NavigationStack {
            DayHabitsListView(date: $selectedDate, entries: entries)
                .navigationTitle("Habits")
        }
        .onAppear() {
            // Set to today's date and refresh when the view appears
            resetToToday()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Reset to today's date when app becomes active
                resetToToday()
            }
        }
        .onChange(of: selectedDate) { _, _ in
            refreshEntries()
        }.refreshable {
            // Just refresh data but don't change the selected date when manually refreshed
            refreshEntries()
        }
    }
    
    private func refreshEntries() {
        // Force a refresh of data from CloudKit
        modelData.refreshData()
        
        logger.log("Refreshing entries for date: \(selectedDate)")
        // Fetch entries for the selected date
        self.entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
    }
    
    private func resetToToday() {
        // Get the current date
        let today = Date()
        
        // Only update if the selected date is not today (comparing calendar days)
        if !Calendar.current.isDate(selectedDate, inSameDayAs: today) {
            logger.log("Resetting to today's date: \(today)")
            selectedDate = today
        } else {
            // If it's already today, just refresh the entries
            refreshEntries()
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
