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
            return ["Back on track!" , "Keep it up!", "Glad you are back!", "You are back!"].randomElement() ?? "Yaaaay!"
        case .completionRenewed2:
            return "Fresh Start! 🌿"
        case .completionRenewed3:
            return "New Beginning! 🌺"
        case .completionTotal30:
            return "30 Total Completions! 🌠"
        case .completionTotal66:
            return "66 Sticking Point! 🧲"
        case .completionTotal100:
            return "Century Club! 💯"
        case .completionTotal365:
            return "365 Days Complete! 📆"
        case .none:
            return ""
        }
    }
    
    private var icon: String {
        switch achievement {
        case .completionStreakWeek:
            return "🔥"
        case .completionStreak2Weeks:
            return "💪"
        case .completionMonth:
            return "🌟"
        case .completionStreak50:
            return "👑"
        case .completionStreak100:
            return "🏆"
        case .completionYear:
            return "🎯"
        case .completionRenewed, .completionRenewed2, .completionRenewed3:
            return "🎉"
        case .completionTotal30:
            return "🌠"
        case .completionTotal66:
            return "🧲"
        case .completionTotal100:
            return "💯"
        case .completionTotal365:
            return "📆"
        case .none:
            return ""
        }
    }
    
    var body: some View {
        VStack {
            if isPresented {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 28))
                        
                        Text(title.replacingOccurrences(of: " \(icon)", with: ""))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .blendMode(.overlay)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                .padding(.horizontal, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPresented)
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


