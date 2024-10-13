//
//  Date.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 09/10/2024.
//


import Foundation

extension Date {
    
    // Check if the selected date is today
    func isToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }

    // Helper function to compare dates by day
    func isSameDay(as date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date2)
    }
}
