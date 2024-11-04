//
//  CircularProgressView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 03/11/2024.
//
import SwiftUI

struct CircularProgressView: View {
    let entries: [DailyEntry]
    let date: Date
    
    var body: some View {
        let weekday = HabitItem.Weekday(date: date)
        let todayEntries = entries.filter {
            $0.date.isSameDay(as: date) && $0.habit.weekdays.contains(weekday)
        }
        let completedEntries = todayEntries.filter { $0.isCompleted }
        let completionRatio = CGFloat(completedEntries.count) / CGFloat(max(todayEntries.count, 1))
        
        
        
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 40, height: 40)
            Circle()
                .trim(from: 0.0, to: completionRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .red]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 40, height: 40)
        }
    }
}
