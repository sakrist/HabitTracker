import SwiftUI

struct TimelineDayGroup: View {
    let group: TimelineGroup
    @State private var showShareSheet = false
    @State private var summaryText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    showShareSheet = true
                }) {
                    
                    Text(group.date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                
//                Spacer()
            }
            
            ForEach(group.entries) { entry in
                TimelineEntryView(timelineEntry: entry)
            }
        }.sheet(isPresented: $showShareSheet) {
            if let summaryText = generateSummary(for: group) {
                ActivityView(activityItems: [summaryText])
            }
        }
    }

    private func generateSummary(for group: TimelineGroup) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        var summary = "Daily Habits Summary\n"
        summary += "📅 \(dateFormatter.string(from: group.date))\n\n"
        
        // Group entries by type
        let completions = group.entries.filter { $0.type == .completion }
        let creations = group.entries.filter { $0.type == .creation }
        let achievements = group.entries.filter { 
            if let dailyEntry = $0.dailyEntry,
               let achievement = dailyEntry.achievement,
               achievement != .none {
                return true
            }
            return false
        }
        
        if !completions.isEmpty {
            summary += "✅ Completed:\n"
            for entry in completions {
                summary += "• \(entry.habit.title) at \(entry.date.formatted(date: .omitted, time: .shortened))\n"
            }
            summary += "\n"
        }
        
        if !achievements.isEmpty {
            summary += "🏆 Achievements:\n"
            for entry in achievements {
                if let achievement = entry.dailyEntry?.achievement {
                    summary += "• \(achievementTitle(achievement:achievement)) for \"\(entry.habit.title)\"\n"
                }
            }
            summary += "\n"
        }
        
        if !creations.isEmpty {
            summary += "🆕 New Habits:\n"
            for entry in creations {
                summary += "• Started tracking \"\(entry.habit.title)\"\n"
            }
        }
        
//        summaryText = summary
        return summary
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
