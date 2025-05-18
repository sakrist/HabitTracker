//
//  ContentView.swift
//  HabitTrackerWatch Watch App
//
//  Created by Volodymyr Boichentsov on 16/05/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    var body: some View {
        NavigationStack {
            DayHabitsListView(date: $selectedDate, entries: entries)
                .navigationTitle("Habits")
        }
        .onAppear() {
            self.entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
