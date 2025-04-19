import SwiftUI

struct TimelineDayGroup: View {
    let group: TimelineGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.date.formatted(date: .complete, time: .omitted))
                .font(.headline)
                .padding(.vertical, 8)
            
            ForEach(group.completionEntries.reversed()) { completionEntry in
                TimelineEntryView(
                    entry: completionEntry.entry,
                    completionDate: completionEntry.completionDate,
                    index: completionEntry.index,
                    totalCompletions: completionEntry.entry.completionDates.count
                )
            }
        }
    }
}

#Preview {
    let sampleHabit = HabitItem.sampleData().first!
    let entry = DailyEntry(habit: sampleHabit, date: Date())
    entry.completionDates = [Date()]
    
    let completionEntry = CompletionEntry(entry: entry, completionDate: Date())
    let group = TimelineGroup(date: Date(), completionEntries: [completionEntry])
    
    return TimelineDayGroup(group: group)
}
