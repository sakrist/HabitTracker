//
//  ContentView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    
    var body: some View {
        TabView {
            Tab("Day", systemImage: "sun.max.fill") {
                DailyHabitListView()
                    .environment(modelData)
            }
            Tab("Calendar", systemImage: "calendar") {
                Text("Calendar")
            }
            Tab("Habits", systemImage: "list.bullet") {
                HabitsListView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
        .modelContainer(SampleData.shared.modelContainer)
}
