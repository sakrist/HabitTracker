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
    
    func isCurrentMonth() -> Bool {
        return isSameMonth(date:Date())
    }
    
    func isSameMonth(date:Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Compare the year and month components
        return calendar.component(.year, from: currentDate) == calendar.component(.year, from: self) &&
               calendar.component(.month, from: currentDate) == calendar.component(.month, from: self)
    }

    // Helper function to compare dates by day
    func isSameDay(as date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date2)
    }
    
    func days(in endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = self
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
}
