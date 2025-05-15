//
//  ModelData+achivments.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 01/04/2025.
//


import SwiftUI
import Foundation

enum Achievement: Int, CaseIterable, Codable {
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
    case completionTotal30 = 31
    case completionTotal66 = 66
    case completionTotal100 = 101
    case completionTotal365 = 366
}
    
func achievementTitle(achievement:Achievement) -> String {
    switch achievement {
    case .completionStreakWeek:
        return "7 Day Streak!"
    case .completionStreak2Weeks:
        return "2 Week Warrior!"
    case .completionMonth:
        return "Monthly Master!"
    case .completionStreak50:
        return "50 Day Champion!"
    case .completionStreak100:
        return "100 Day Legend!"
    case .completionYear:
        return "Year of Excellence!"
    case .completionRenewed:
        return ["Back on track!" , "Keep it up!", "Glad you are back!", "You are back!"].randomElement() ?? "Yaaaay!"
    case .completionRenewed2:
        return "Fresh Start!"
    case .completionRenewed3:
        return "New Beginning!"
    case .completionTotal30:
        return "30 Total Completions!"
    case .completionTotal66:
        return "66 Sticking Point!"
    case .completionTotal100:
        return "Century Club!"
    case .completionTotal365:
        return "365 Days Complete!"
    case .none:
        return ""
    }
}

func achievementIcon(achievement:Achievement) -> String {
    switch achievement {
    case .completionStreakWeek:
        return "🔥"
    case .completionStreak2Weeks:
        return "💪"
    case .completionMonth:
        return "🌟"
    case .completionStreak50:
        return "👑"
    case .completionStreak100:
        return "🏆"
    case .completionYear:
        return "🎯"
    case .completionRenewed:
        return "👍"
    case .completionRenewed2:
        return "🌱"
    case .completionRenewed3:
        return "🥹"
    case .completionTotal30:
        return "⭐️"
    case .completionTotal66:
        return "🧲"
    case .completionTotal100:
        return "💯"
    case .completionTotal365:
        return "🥳"
    case .none:
        return ""
    }
}


extension ModelData {
    
    func completedEntry(entry: DailyEntry) -> Achievement {
        // Don't process if the entry wasn't completed
        guard entry.isCompleted else { return .none }
        
        // Check streak-based achievements
        let (streak, _, _, total) = calculateStreak(habit: entry.habitt, for: .endOfDay())
        
        // Log current streak for debugging
        print("Current streak for \(entry.habitt.title): \(streak)")
        
        // Check if this is a milestone streak
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
            // Continue to other checks
            break
        }

        switch total {
        case 30:
            return .completionTotal30
        case 66:
            return .completionTotal66
        case 100:
            return .completionTotal100
        case 365:
            return .completionTotal365
        default:
            // Continue to other checks
            break
        }
        
        // Check for habit renewal patterns (when a habit is resumed after a break)
        // First, find the previous completion date
        let startDate = entry.habitt.timestamp.prevDay()
        let endDate = Date.endOfDay().prevDay()
        
        var previousEntries = fetchEntries(start: startDate, end: endDate, habit: entry.habitt, modelContext: modelContainer.mainContext)
        previousEntries.sort { $0.date > $1.date }
        
        // If this is the first completion or we have a limited history, don't show renewal
        guard !previousEntries.isEmpty else { return .none }
        
        // Find the most recent completed entry
        if let lastCompletedEntry = previousEntries.first(where: { $0.isCompleted }) {
            // Calculate days since last completion
            let daysSinceLastCompletion = (Calendar.current.dateComponents(
                [.day],
                from: lastCompletedEntry.date,
                to: entry.date
            ).day ?? 0)
            
            // Return appropriate renewal achievement based on gap duration
            if daysSinceLastCompletion >= 28 { // 4+ weeks
                return .completionRenewed3
            } else if daysSinceLastCompletion >= 14 { // 2-4 weeks
                return .completionRenewed2
            } else if daysSinceLastCompletion >= 5 { // 5 days to 2 weeks
                return .completionRenewed
            }
        }
        
        // No special achievements apply
        return .none
    }
    
    func weeklySummary() {
        // TODO: implement weekly summary
    }
        
}
