//
//  AchievementBanner.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 04/04/2025.
//

import SwiftUI

struct AchievementBanner: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    
    private var title: String {
        switch achievement {
        case .completionStreakWeek:
            return "7 Day Streak! 🔥"
        case .completionStreak2Weeks:
            return "2 Week Warrior! 💪"
        case .completionMonth:
            return "Monthly Master! 🌟"
        case .completionStreak50:
            return "50 Day Champion! 👑"
        case .completionStreak100:
            return "100 Day Legend! 🏆"
        case .completionYear:
            return "Year of Excellence! 🎯"
        case .completionRenewed:
            return "Welcome Back! 🌱"
        case .completionRenewed2:
            return "Fresh Start! 🌿"
        case .completionRenewed3:
            return "New Beginning! 🌺"
        case .none:
            return ""
        }
    }
    
    var body: some View {
        VStack {
            if isPresented {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
//                        .rainbowRun()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.9))
//                        .shiny()
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
        .onTapGesture {
            isPresented = false
        }
    }
}


#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        
        AchievementBanner(achievement: .completionStreakWeek, isPresented: .constant(true))
            .padding()
    }
}


