//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let modelData = ModelData()
    
    // this will clear storage and populate sample data
//    let sample = SampleData.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                
        }
        .modelContainer(modelData.modelContainer)
        .environment(modelData)
    }
}
