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
    @State private var selectedTab = -1
    @State private var firstTab = 0
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyHabitListView(selectedTab: $selectedTab)
                .environment(modelData)
                .tabItem {
                    Label("Day", systemImage: "sun.max.fill")
                }
                .tag(firstTab)
                .onChange(of: selectedTab) { oldValue, newValue in
                    if (firstTab == selectedTab) {
                        firstTab = (selectedTab == 0) ? -1 : 0
                        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                    }
                }
            
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
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
