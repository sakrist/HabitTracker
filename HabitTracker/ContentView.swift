//
//  ContentView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import SwiftUI
import SwiftData

let monthCompletionData: [Int] = (1...30).map { _ in Int.random(in: 0...5) }


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyHabitListView(selectedTab: $selectedTab)
                .environment(modelData)
                .tabItem {
                    Label("Day", systemImage: "sun.max.fill")
                }
                .tag(0)
            
            HabitsListView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
        .modelContainer(SampleData.shared.modelContainer)
}
