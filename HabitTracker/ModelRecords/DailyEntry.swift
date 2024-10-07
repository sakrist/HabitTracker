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
    var title: String?
    var habit: HabitItem?
    var date: Date
    var isCompleted: Bool = false
    
    init(title: String?, habit: HabitItem?, date: Date, isCompleted: Bool) {
        self.date = date
        self.isCompleted = isCompleted
        self.habit = habit
    }

}
