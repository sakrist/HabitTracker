import SwiftUI

struct TimelineEntryView: View {
    let entry: TimelineEntry
    
    // Legacy initializer for compatibility
    init(entry: DailyEntry, completionDate: Date, index: Int = 0, totalCompletions: Int = 1) {
        self.entry = TimelineEntry(entry: entry, completionDate: completionDate)
    }
    
    // New initializer
    init(timelineEntry: TimelineEntry) {
        self.entry = timelineEntry
    }
    
    var body: some View {
        switch entry.type {
        case .completion:
            completionEntryView
        case .creation:
            habitCreationView
        }
    }
    
    // The original completion view
    private var completionEntryView: some View {
        guard let dailyEntry = entry.dailyEntry else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                // Show achievement above the habit if present
                if let achievement = dailyEntry.achievement, achievement != .none && entry.index == dailyEntry.completionDates.count-1 {
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
                                Text("(\(entry.index + 1)/\(entry.habit.targetCount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.leading, 12)
                }
            }
        )
    }
    
    // New view for habit creation
    private var habitCreationView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                TimelineConnector(color: entry.habit.getColor())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(entry.habit.getColor())
                        
                        Text("Created Habit: \(entry.habit.title)")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        
                        Spacer()
                        
                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show habit configuration details
                    HStack(spacing: 8) {
                        if !entry.habit.weekdays.isEmpty {
                            Text("Days: \(formatWeekdays(entry.habit.weekdays))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if entry.habit.targetCount > 1 {
                            Text("Target: \(entry.habit.targetCount)× daily")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let category = entry.habit.category?.title, !category.isEmpty {
                            Text("Category: \(category)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !entry.habit.note.isEmpty {
                        Text("Note: \(entry.habit.note)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.habit.getColor().opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(entry.habit.getColor().opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.leading, 12)
                .padding(.vertical, 4)
            }
        }
    }
    
    // Helper to format weekdays nicely
    private func formatWeekdays(_ weekdays: Set<HabitItem.Weekday>) -> String {
        if weekdays.count == 7 {
            return "Every day"
        }
        return weekdays.sorted(by: { $0.rawValue < $1.rawValue })
            .map { $0.abbreviatedName }
            .joined(separator: ", ")
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
            timelineEntry: TimelineEntry(entry: entry, completionDate: Date())
        )
        
        TimelineEntryView(
            timelineEntry: TimelineEntry(entry: achievementEntry, completionDate: Date())
        )
        
        TimelineEntryView(
            timelineEntry: TimelineEntry(entry: multiEntry, completionDate: multiEntry.completionDates.last!)
        )

        Spacer().frame(height: 200)
    }
    .padding()
    
}
