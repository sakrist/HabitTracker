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
    
    static func endOfDay() -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: .now) ?? .now
    }
    
    func nextDay() -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self) ?? .now
    }
    
    func prevDay() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? .now
    }
    
    func isCurrentMonth() -> Bool {
        return isSameMonth(date:Date())
    }
    
    func daysBetween(to date: Date) -> Int {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day], from: self, to: date)
        return dateComponents.day ?? 0
    }
    
    func isSameMonth(date:Date) -> Bool {
        let calendar = Calendar.current
        
        // Compare the year and month components
        return calendar.component(.year, from: date) == calendar.component(.year, from: self) &&
               calendar.component(.month, from: date) == calendar.component(.month, from: self)
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
