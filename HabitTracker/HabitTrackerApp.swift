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
    let modelData = ModelData.shared
    @Environment(\.scenePhase) private var scenePhase
    
#if DEBUG
    // this will clear storage and populate sample data
//    let sample = SampleData.shared
#endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    checkNotificationPermission { value in
                        modelData.notificationsEnabled = value
                    }
                }
                .onChange(of: scenePhase) { old, newPhase in
                    if newPhase == .background {
                        
                    }
                }
        }
        .modelContainer(modelData.modelContainer)
        .environment(modelData)
    }
}
