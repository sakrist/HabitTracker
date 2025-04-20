//
//  OnboardingHabitsView.swift
//  HabitTracker
//

import SwiftUI

struct OnboardingHabitsView: View {
    @Binding var selectedHabits: [Bool]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Habits")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Select habits you'd like to track \nor add your owns later.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 12) {
                    Spacer().frame(height: 4)
                    ForEach(0..<commonHabits.count, id: \.self) { index in
                        let habit = commonHabits[index]
                        
                        HabitSelectionRow(
                            title: habit.title,
                            icon: habit.icon,
                            description: habit.description,
                            color: Color(hex: habit.color) ?? .blue,
                            hasHealth: habit.healthType != .none,
                            isSelected: selectedHabits[index]
                        ) {
                            selectedHabits[index].toggle()
                        }
                    }
                    Spacer().frame(height: 4)
                }
                .padding(.horizontal)
            }
            
            VStack {
                Text("You've selected \(selectedHabits.filter { $0 }.count) habits")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                if selectedHabits.filter({ $0 }).isEmpty {
                    Text("You can always add habits later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

struct HabitSelectionRow: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let hasHealth: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(.headline, design: .rounded))
                        
                        if hasHealth {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : .gray.opacity(0.5))
                    .font(.system(size: 22))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview for OnboardingHabitsView
#Preview {
    OnboardingHabitsView(selectedHabits: .constant(Array(repeating: false, count: commonHabits.count)))
}
