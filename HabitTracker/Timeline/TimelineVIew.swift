//
//  TimelineView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 18/04/2025.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var reload: Bool
    @State private var timelineItems: [TimelineGroup] = []
    @State private var isLoading = false
    @State private var currentDate = Date()
    @State private var loadedDates = Set<Date>() // Track loaded dates
    let batchSize = 30 // Days to load at a time
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(timelineItems) { group in
                    TimelineDayGroup(group: group)
                }
                
                if !isLoading {
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 20)
                }
            }
            .padding(.horizontal)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            if offset > -100 && !isLoading {
                loadMoreContent()
            }
        }
        .onAppear {
            if (timelineItems.isEmpty) {
                loadInitialContent()
            }
        }
        .onChange(of: reload) { _, newValue in
            if newValue && !timelineItems.isEmpty && !isLoading {
                timelineItems.removeAll()
                loadedDates.removeAll()
                currentDate = Date()
                loadInitialContent()
                DispatchQueue.main.async {
                    reload = false
                }
            }
        }
    }
    
    private func loadInitialContent() {
        loadTimelineItems(from: currentDate)
    }
    
    private func loadMoreContent() {
        isLoading = true
        currentDate = Calendar.current.date(byAdding: .day, value: -batchSize, to: currentDate) ?? currentDate
        loadTimelineItems(from: currentDate)
        isLoading = false
    }
    
    private func loadTimelineItems(from date: Date) {
        let startDate = date
        let endDate = Calendar.current.date(byAdding: .day, value: batchSize, to: startDate) ?? date
        
        // Check if we've already loaded this date range
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        if loadedDates.contains(startDay) {
            return
        }
        loadedDates.insert(startDay)
        
        let entries = fetchEntries(start: startDate, end: endDate, modelContext: modelContext)
        
        // Group entries by completion date
        var groupedByDay: [Date: [CompletionEntry]] = [:]
        
        for entry in entries {
            // Only include completed entries
            guard entry.isCompleted else { continue }
            
            for completionDate in entry.completionDates {
                let dayStart = calendar.startOfDay(for: completionDate)
                if groupedByDay[dayStart] == nil {
                    groupedByDay[dayStart] = []
                }
                
                groupedByDay[dayStart]?.append(CompletionEntry(entry: entry, completionDate: completionDate))
            }
        }
        
        // Convert to timeline groups
        let newGroups = groupedByDay.map { date, entries in
            TimelineGroup(
                date: date,
                completionEntries: entries.sorted { $0.completionDate < $1.completionDate }
            )
        }.sorted { $0.date > $1.date }
        
        // Only append groups that aren't already present
        let existingDates = Set(timelineItems.map { calendar.startOfDay(for: $0.date) })
        let uniqueGroups = newGroups.filter { !existingDates.contains(calendar.startOfDay(for: $0.date)) }
        
        timelineItems.append(contentsOf: uniqueGroups)
        timelineItems.sort { $0.date > $1.date } // Ensure proper ordering
    }
}

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

struct TimelineConnector: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2)
        }
    }
}

// Model to hold completion entry info
struct CompletionEntry: Identifiable {
    let id = UUID()
    let entry: DailyEntry
    let completionDate: Date
    let index: Int
    
    init(entry: DailyEntry, completionDate: Date) {
        self.entry = entry
        self.completionDate = completionDate
        if let index = entry.completionDates.firstIndex(of: completionDate) {
            self.index = index
        } else {
            self.index = 0
        }
    }
}

struct TimelineGroup: Identifiable {
    let id = UUID()
    let date: Date
    let completionEntries: [CompletionEntry]
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

@MainActor private func setupPreviewData() -> ModelContainer {
    let schema = Schema(versionedSchema: SchemaLatest.self)
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    // Create some sample entries with varied completion dates
    let sampleHabits = HabitItem.sampleData()
    
    // Create entries for the past 14 days
    let calendar = Calendar.current
    for daysAgo in 0...14 {
        guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
        
        for habit in sampleHabits {
            let entry = DailyEntry(habit: habit, date: date)
            
            // Add multiple completions for habits with targetCount > 1
            if habit.targetCount > 1 {
                for i in 0..<habit.targetCount {
                    if let completionTime = calendar.date(byAdding: .hour, value: i * 6, to: date) {
                        entry.completionDates.append(completionTime)
                    }
                }
            } else {
                // Single completion with random time
                if Bool.random() {
                    if let completionTime = calendar.date(byAdding: .hour, value: Int.random(in: 0...23), to: date) {
                        entry.completionDates = [completionTime]
                    }
                }
            }
            
            // Add some achievements
            if daysAgo == 7 {
                entry.achievement = .completionStreakWeek
            } else if daysAgo == 14 {
                entry.achievement = .completionStreak2Weeks
            }
            
            context.insert(entry)
        }
    }
    
    return container
}

#Preview {
    TimelineView(reload:.constant(false))
        .modelContainer(setupPreviewData())
}

