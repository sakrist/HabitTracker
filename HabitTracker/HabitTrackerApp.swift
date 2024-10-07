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
    let sharedModelContainer = createSharedModelContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
