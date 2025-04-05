//
//  ModelData+achivments.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 01/04/2025.
//


enum Achievement: Int {
    case none = 0
    case completionRenewed = 1 // completed habit that had not been completed between 2 days to the 2 weeks
    case completionRenewed2 = 2 // completed habit that had not been completed for more then 2-4 weeks
    case completionRenewed3 = 3 // completed habit that had not been completed for more then 4 weeks
    case completionStreakWeek = 7
    case completionStreak2Weeks = 14
    case completionMonth = 30
    case completionStreak50 = 50
    case completionStreak100 = 100
    case completionYear = 365
}
    


extension ModelData {
    
    func completedEntry(entry: DailyEntry) -> Achievement {
        let (streak, completionRate, longest, total) = calculateStreak(habit: entry.habit, for: .endOfDay())
            
        print("current streak: \(streak)")
        
        switch streak {
            case 7:
                return .completionStreakWeek
            case 14:
                return .completionStreak2Weeks
            case 30:
                return .completionMonth
            case 50:
                return .completionStreak50
            case 100:
                return .completionStreak100
            case 365, 730, 1095:
                return .completionYear
            default:
                break
        }

        // TODO: analyze renewed completions
        // for testing
        return .completionStreakWeek
        
        // TODO: do one of this
        /*
         5, 10, 25, 50, 100 completions: Congratulate with a pop-up or animated banner.
         •    7-Day Streak, 30-Day Streak, etc.: Show a badge or notification.
         •    All Scheduled Habits Completed in a Week: Special celebration message.
         •    Personal Best: If a habit is completed more times than in any previous week, highlight it.
         */
        
        return .none
    }
    
    func weeklySummary() {
        // TODO: implement weekly summary
    }
        
}
