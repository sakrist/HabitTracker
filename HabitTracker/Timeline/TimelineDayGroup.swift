import SwiftUI

struct TimelineDayGroup: View {
    let group: TimelineGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.date.formatted(date: .complete, time: .omitted))
                .font(.headline)
                .padding(.vertical, 8)
            
            ForEach(group.entries) { entry in
                TimelineEntryView(timelineEntry: entry)
            }
        }
    }
}

#Preview {
    let sampleHabit = HabitItem.sampleData().first!
    
    // Create a sample creation entry
    let creationEntry = TimelineEntry(habit: sampleHabit)
    
    // Create a sample completion entry
    let dailyEntry = DailyEntry(habit: sampleHabit, date: Date())
    dailyEntry.completionDates = [Date()]
    let completionEntry = TimelineEntry(entry: dailyEntry, completionDate: Date())
    
    let group = TimelineGroup(date: Date(), entries: [creationEntry, completionEntry])
    
    return TimelineDayGroup(group: group)
}
