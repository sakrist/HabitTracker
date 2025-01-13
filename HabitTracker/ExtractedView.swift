//
//  ExtractedView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/01/2025.
//


struct ExtractedView: View {
    
    @State private var activeWeekdays: Set<HabitItem.Weekday>
    
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
}