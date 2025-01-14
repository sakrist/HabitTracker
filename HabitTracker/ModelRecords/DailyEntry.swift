//
//  DailyHabitEntry.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 29/09/2024.
//

import Foundation
import SwiftData



@Model
class DailyEntry : ObservableObject {
    var habit: HabitItem
    var date: Date
    var isCompleted: Bool = false
    
    init(habit: HabitItem, date: Date, isCompleted: Bool) {
        self.date = date
        self.isCompleted = isCompleted
        self.habit = habit
    }
    
    var title:String {
        return self.habit.title
    }
}

func sortDailyHabits(item1: DailyEntry, item2: DailyEntry) -> Bool {
    if item1.habit.isTimeSensitive != item2.habit.isTimeSensitive {
        return item1.habit.isTimeSensitive // Time-sensitive items come first
    }
    
    if let time1 = item1.habit.time, let time2 = item2.habit.time {
        // Both times are non-nil; compare directly
        if time1 != time2 {
            return time1 < time2
        }
    } else if item1.habit.time != nil {
        // item1 has a time, item2 does not; item1 should come first
        return true
    } else if item2.habit.time != nil {
        // item2 has a time, item1 does not; item2 should come first
        return false
    }
    
    // If times are equal or both are nil, fall back to order
    return item1.habit.order < item2.habit.order
}
