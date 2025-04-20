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
    
    @State private var showOnboarding = false
    
#if DEBUG
    // this will clear storage and populate sample data
//    let sample = SampleData.shared
#endif
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
                    .opacity(showOnboarding ? 0 : 1)
                    .disabled(showOnboarding)
                
                if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Check if we need to show onboarding
                let hasCompletedOnboarding = true //UserDefaults.standard.bool(forKey: "OnboardingCompleted")
                showOnboarding = !hasCompletedOnboarding
            }
            .animation(.easeInOut, value: showOnboarding)
        }
        .modelContainer(modelData.modelContainer)
        .environment(modelData)
    }
}
