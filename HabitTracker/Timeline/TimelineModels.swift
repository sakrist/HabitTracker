import SwiftUI
import SwiftData

// Define types of timeline entries
enum TimelineEntryType {
    case completion
    case creation
}

// Model to hold all timeline entry info
struct TimelineEntry: Identifiable {
    let id = UUID()
    let type: TimelineEntryType
    let habit: HabitItem
    let date: Date
    let dailyEntry: DailyEntry?
    let index: Int
    
    // For completion entries
    init(entry: DailyEntry, completionDate: Date) {
        self.type = .completion
        self.habit = entry.habitt
        self.dailyEntry = entry
        self.date = completionDate
        if let index = entry.completionDates.firstIndex(of: completionDate) {
            self.index = index
        } else {
            self.index = 0
        }
    }
    
    // For creation entries
    init(habit: HabitItem) {
        self.type = .creation
        self.habit = habit
        self.dailyEntry = nil
        self.date = habit.timestamp
        self.index = 0
    }
}

struct TimelineGroup: Identifiable {
    let id = UUID()
    let date: Date
    let entries: [TimelineEntry]
}
