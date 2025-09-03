//
//  HabitTrackerWatchApp.swift
//  HabitTrackerWatch Watch App
//
//  Created by Volodymyr Boichentsov on 16/05/2025.
//

import SwiftUI
import SwiftData

@main
struct HabitTrackerWatchApp: App {
    
//    let sample = SampleData.shared
    let modelData = ModelData.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelData.modelContainer)
                .environment(modelData)
        }
    }
}
