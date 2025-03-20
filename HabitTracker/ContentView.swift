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
    
    // show view to add new habit
    @State private var showAddHabit = false
    @State private var habitsNavigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainListView(selectedTab: $selectedTab,
                         showAddHabit: $showAddHabit,
                         navigationPath: $habitsNavigationPath)
                .environment(modelData)
                .tabItem {
                    Label("Day View", systemImage: "sun.max.fill")
                }
                .tag(firstTab)
                .onChange(of: selectedTab) { oldValue, newValue in
                    if (firstTab == selectedTab) {
                        showAddHabit = false
                        habitsNavigationPath = NavigationPath()
                        firstTab = (selectedTab == 0) ? -1 : 0
                        postActive()
                    }
                }
            
            HabitsListView(showAddHabit: $showAddHabit, navigationPath: $habitsNavigationPath)
                .tabItem {
                    Label("Habits List", systemImage: "list.bullet")
                }
                .tag(1)
            
//            HealthViewDebug().tabItem {
//                Label("Debug", systemImage: "list.bullet")
//            }
//            .tag(2)

        }
    }
    
    func postActive() {
        #if canImport(UIKit)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif canImport(AppKit)
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        #else
        fatalError("Unsupported platform")
        #endif
    }
}

#Preview {
    ContentView()
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
