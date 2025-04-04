//
//  ModelData+achivments.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 01/04/2025.
//

extension ModelData {
    
    func completedEntry(entry: DailyEntry) {
        let (streak, completionRate, longest, total) = calculateStreak(habit: entry.habit, for: .endOfDay())
            
        print("current streak: \(streak)")
        
    
        
        
        // TODO: do one of this
        /*
         5, 10, 25, 50, 100 completions: Congratulate with a pop-up or animated banner.
         •    7-Day Streak, 30-Day Streak, etc.: Show a badge or notification.
         •    All Scheduled Habits Completed in a Week: Special celebration message.
         •    Personal Best: If a habit is completed more times than in any previous week, highlight it.
         */
    }
    
    func weeklySummary() {
        // TODO: implement weekly summary
    }
        
}
