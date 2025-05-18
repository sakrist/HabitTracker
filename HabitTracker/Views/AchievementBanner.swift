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
    let color: Color
    @Binding var isPresented: Bool
    
    // Provide default blue color for backward compatibility
    init(title: String, icon: String, color: Color = .blue, isPresented: Binding<Bool>) {
        self.title = title
        self.icon = icon
        self.color = color
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack {
            if isPresented {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 28))
                        
                        Text(title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                        #if os(iOS)
                            .rainbowRun()
                        #endif
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        // White background base layer
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: UIColor.systemBackground))
                        
                        // Colored overlay
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.15))
                        
                        // Border
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    }
                )
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
        
        VStack(spacing: 20) {
            // Show with default blue color
            AchievementBanner(title: "7 Day Streak!", icon: "🔥", isPresented: .constant(true))
                .padding()
            
            // Show with custom color
            AchievementBanner(title: "14 Day Streak!", icon: "🏆", color: .green, isPresented: .constant(true))
                .padding()
            
            // Show with red color
            AchievementBanner(title: "30 Day Streak!", icon: "⭐", color: .red, isPresented: .constant(true))
                .padding()
        }
    }
}


