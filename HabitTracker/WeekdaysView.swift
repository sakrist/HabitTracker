//
//  WeekdaysView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/01/2025.
//
import SwiftUI


// Custom multi-segment control for weekdays
struct WeekdaysView: View {
    
    @Binding var activeWeekdays: Set<HabitItem.Weekday>
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(HabitItem.Weekday.allCases) { day in
                Button(action: {
                    toggleDaySelection(day)
                }) {
                    Text(day.displayName)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(activeWeekdays.contains(day) ? Color.blue : Color.clear)
                        .foregroundColor(activeWeekdays.contains(day) ? .white : .blue)
                }
                .buttonStyle(PlainButtonStyle())  // Remove default button style
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
    }
    
    private func toggleDaySelection(_ day: HabitItem.Weekday) {
        if activeWeekdays.contains(day) {
            activeWeekdays.remove(day)
        } else {
            activeWeekdays.insert(day)
        }
    }
}


#Preview {
    var activeWeekdays = Set(HabitItem.Weekday.allCases)
    WeekdaysPreviewWrapper()
}

// A wrapper view to simulate the binding
struct WeekdaysPreviewWrapper: View {
    @State private var activeWeekdays: Set<HabitItem.Weekday> = [.monday, .wednesday, .friday]

    var body: some View {
        WeekdaysView(activeWeekdays: $activeWeekdays)
            .padding()
            .previewLayout(.sizeThatFits) // Fit to content size
    }
}
