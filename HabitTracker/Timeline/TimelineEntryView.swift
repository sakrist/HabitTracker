import SwiftUI

struct TimelineEntryView: View {
    let entry: DailyEntry
    let completionDate: Date
    let index: Int
    let totalCompletions: Int
    
    init(entry: DailyEntry, completionDate: Date, index: Int = 0, totalCompletions: Int = 1) {
        self.entry = entry
        self.completionDate = completionDate
        self.index = index
        self.totalCompletions = totalCompletions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show achievement above the habit if present
            if let achievement = entry.achievement, achievement != .none && index == totalCompletions-1 {
                HStack(alignment: .center, spacing: 0) {
                    TimelineConnector(color: entry.habit.getColor())
                    
                    HStack {
                        Text(achievementIcon(achievement: achievement))
                        Text(achievementTitle(achievement: achievement))
                            .font(.system(.body, design: .rounded))
                            .rainbowRun()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entry.habit.getColor().opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(entry.habit.getColor().opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.leading, 12)
                    .padding(.bottom, 4)
                }
            }
            
            // Show the habit entry
            HStack(alignment: .center, spacing: 0) {
                TimelineConnector(color: entry.habit.getColor())
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.habit.title)
                            .font(.system(.body, design: .rounded))
                        
                        if entry.habit.healthType != .none {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.caption)
                        }
                        
                        if entry.habit.targetCount > 1 {
                            Text("(\(index + 1)/\(entry.habit.targetCount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(completionDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.leading, 12)
            }
        }
    }
}

#Preview {
    // Create sample data
    let sampleHabit = HabitItem.sampleData().first!
    
    // Basic entry
    let entry = DailyEntry(habit: sampleHabit, date: Date())
    entry.completionDates = [Date()]
    
    // Entry with achievement
    let achievementEntry = DailyEntry(habit: sampleHabit, date: Date())
    achievementEntry.completionDates = [Date()]
    achievementEntry.achievement = .completionStreakWeek
    
    // Multiple completions entry
    let multiEntry = DailyEntry(habit: sampleHabit, date: Date())
    multiEntry.completionDates = [
        Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
        Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
        Date()
    ]
    multiEntry.achievement = .completionStreak2Weeks
    
    return VStack(spacing: 20) {
        Spacer().frame(height: 200)

        TimelineEntryView(
            entry: entry,
            completionDate: Date(),
            index: 0,
            totalCompletions: 1
        )
        
        TimelineEntryView(
            entry: achievementEntry,
            completionDate: Date(),
            index: 0,
            totalCompletions: 1
        )
        
        TimelineEntryView(
            entry: multiEntry,
            completionDate: multiEntry.completionDates.last!,
            index: 2,
            totalCompletions: 3
        )

        Spacer().frame(height: 200)
    }
    .padding()
    
}
