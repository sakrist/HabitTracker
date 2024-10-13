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
