import SwiftUI

struct TimelineDayGroup: View {
    let group: TimelineGroup
    @State private var showShareSheet = false
    @State private var summaryText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(group.date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        generateSummary(for: group)
                        showShareSheet = true
                    }
                    .sheet(isPresented: $showShareSheet) {
#if os(iOS)
                        ActivityView(activityItems: [summaryText])
#else
                        ShareLink(item: summaryText)
#endif
                    }
                
                Spacer()
                
                Button(action: {
                    generateSummary(for: group)
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .padding(.trailing, 8)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Share summary")
            }
            
            ForEach(group.entries) { entry in
                TimelineEntryView(timelineEntry: entry)
            }
        }
    }

    private func generateSummary(for group: TimelineGroup) {
        // Placeholder for summarization logic
        // Replace this with actual summarization code later
        summaryText = "Summary for \(group.date.formatted(date: .complete, time: .omitted)):\n"
        for entry in group.entries {
            summaryText += "- \(entry.habit.title) at \(entry.date.formatted(date: .omitted, time: .shortened))\n"
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
