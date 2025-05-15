//
//  HabitItem.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import Foundation
import SwiftData
import SwiftUI



extension HabitItem {
    
    func deactivate() {
        active.toggle()
        deactivated = .now
    }
    
    var isActive: Bool {
        return active
    }
    
    var isTimeSensitive: Bool {
        return time != nil
    }
    
    func getColor() -> Color {
        return Color(hex: color) ?? .blue
    }
    
    func calendarWeekdays() -> [Int] {
        var weekdaysArray: [Int] = .init()
        for weekday in weekdays {
            weekdaysArray.append(weekday.rawValue+1)
        }
        return weekdaysArray
    }
    
    // Computed property to format the time as a string
    var formattedTime: String {
        if let time = time {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("j:mm")
            return formatter.string(from: time)
        }
        return ""
    }
    
    static private func dateAt(for date: Date, hour: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
    
}

    
func sortHabits(item1: HabitItem, item2: HabitItem) -> Bool {
    if item1.isTimeSensitive != item2.isTimeSensitive {
        return item1.isTimeSensitive // Time-sensitive items come first
    }
    
    if let time1 = item1.time, let time2 = item2.time {
        // Both times are non-nil; compare directly
        if time1 != time2 {
            return time1 < time2
        }
    } else if item1.time != nil {
        // item1 has a time, item2 does not; item1 should come first
        return true
    } else if item2.time != nil {
        // item2 has a time, item1 does not; item2 should come first
        return false
    }
    
    // If times are equal or both are nil, fall back to order
    return item1.order < item2.order
}
