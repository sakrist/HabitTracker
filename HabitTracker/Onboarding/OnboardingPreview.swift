//
//  OnboardingPreview.swift
//  HabitTracker
//

import SwiftUI

struct OnboardingPreview: View {
    @State private var showOnboarding = true
    
    var body: some View {
        OnboardingView(showOnboarding: $showOnboarding)
    }
}

#Preview {
    OnboardingPreview()
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
