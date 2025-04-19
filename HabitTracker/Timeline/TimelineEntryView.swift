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
                    
                    if let achievement = entry.achievement, index == 0 {
                        Text(achievementIcon(achievement: achievement))
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

#Preview {
    let sampleHabit = HabitItem.sampleData().first!
    let entry = DailyEntry(habit: sampleHabit, date: Date())
    entry.completionDates = [Date()]
    
    return TimelineEntryView(
        entry: entry,
        completionDate: Date(),
        index: 0,
        totalCompletions: 1
    )
}
