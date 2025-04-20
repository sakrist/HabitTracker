//
//  OnboardingIntroView.swift
//  HabitTracker
//

import SwiftUI
import RainbowUI

struct OnboardingIntroView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App icon or logo
            Image("Icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.blue, lineWidth: 2))
            
            // App name
            Text("Daily Habit Tracker")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .rainbowRun()
                .padding(.bottom, 10)
            
            // App description
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "checkmark.circle.fill", 
                    title: "Track Your Daily Habits",
                    description: "Build consistency with simple daily tracking"
                )
                
                FeatureRow(
                    icon: "heart.fill", 
                    title: "Health Integration",
                    description: "Automatically track habits linked to Apple Health"
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis", 
                    title: "Monitor Progress",
                    description: "See your streaks and achievements over time"
                )
                
                FeatureRow(
                    icon: "bell.fill", 
                    title: "Helpful Reminders",
                    description: "Get notifications to keep you on track"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingIntroView()
}
