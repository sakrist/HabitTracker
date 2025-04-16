//
//  AchievementBanner.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 04/04/2025.
//

import SwiftUI

struct AchievementBanner: View {
    let title: String
    let icon: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            if isPresented {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 28))
                        
                        Text(title)
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
        
        AchievementBanner(title: "7 Day Streak!", icon: "🔥", isPresented: .constant(true))
            .padding()
    }
}


