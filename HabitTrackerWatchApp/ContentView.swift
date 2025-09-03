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
    
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    var body: some View {
        NavigationStack {
            DayHabitsListView(date: selectedDate)
                .navigationTitle("Habits")
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Reset to today's date when app becomes active
                resetToToday()
            }
        }
    }
    
    private func resetToToday() {
        // Get the current date
        let today = Date()
        
        // Only update if the selected date is not today (comparing calendar days)
        if !Calendar.current.isDate(selectedDate, inSameDayAs: today) {
            logger.log("Resetting to today's date: \(today)")
            selectedDate = today
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
