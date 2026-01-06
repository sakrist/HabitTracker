//
//  CompactTimelineView.swift
//  HabitTracker
//
//  Created by GitHub Copilot on 05/01/2026.
//

import SwiftUI
import SwiftData

struct WeekRow: Identifiable {
    let id = UUID()
    let weekStart: Date
    let days: [DayCompletion]
}

struct DayCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let completionPercentage: Int
    let hasData: Bool
}

struct CompactTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var weekRows: [WeekRow] = []
    @State private var isLoading = false
    @State private var earliestDate: Date = Date()
    @State private var showFilterSheet = false
    @State private var allHabits: [HabitItem] = []
    @State private var selectedHabitIDs: Set<String> = []
    @State private var hasMoreData = true
    @State private var earliestHabitDate: Date?
    @State private var isLoadingMore = false
    @State private var loadTask: Task<Void, Never>?
    
    private let calendar = Calendar.current
    
    // Get the system's first weekday setting
    private var firstWeekday: Int {
        calendar.firstWeekday
    }
    
    // Generate weekday headers based on system settings
    private var weekdayHeaders: [String] {
        // HabitItem.Weekday.allCases starts with Monday (rawValue 0)
        // Calendar.firstWeekday is 1=Sunday, 2=Monday, etc.
        
        var headers: [String] = []
        for i in 0..<7 {
            // Calculate which weekday this column represents
            // firstWeekday 1=Sunday, 2=Monday, etc.
            let weekdayNumber = ((calendar.firstWeekday - 1 + i) % 7) + 1
            
            // Convert to HabitItem.Weekday
            // weekdayNumber: 1=Sunday, 2=Monday, 3=Tuesday, etc.
            let habitWeekday: HabitItem.Weekday
            switch weekdayNumber {
            case 1: habitWeekday = .sunday
            case 2: habitWeekday = .monday
            case 3: habitWeekday = .tuesday
            case 4: habitWeekday = .wednesday
            case 5: habitWeekday = .thursday
            case 6: habitWeekday = .friday
            case 7: habitWeekday = .saturday
            default: habitWeekday = .sunday
            }
            
            headers.append(habitWeekday.abbreviatedName)
        }
        
        return headers
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Filter status bar
                if !selectedHabitIDs.isEmpty && selectedHabitIDs.count < allHabits.count {
                    filterStatusBar
                }
                
                // Header with weekday names
                headerRow
                
                Divider()
                
                // Week rows
                LazyVStack(spacing: 4) {
                    ForEach(weekRows) { weekRow in
                        weekRowView(weekRow)
                            .onAppear {
                                // Load more when approaching the last few weeks
                                if weekRow.id == weekRows.last?.id || 
                                   (weekRows.count > 3 && weekRow.id == weekRows[weekRows.count - 3].id) {
                                    scheduleLoadMore()
                                }
                            }
                    }
                    
                    // Loading indicator at bottom
                    if isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            if weekRows.isEmpty {
                loadAllHabits()
                loadInitialWeeks()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showFilterSheet = true
                }) {
                    Label("Filter Habits", systemImage: "line.3.horizontal.decrease.circle")
                        .symbolVariant(selectedHabitIDs.isEmpty || selectedHabitIDs.count == allHabits.count ? .none : .fill)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            habitFilterSheet
        }
    }
    
    private var filterStatusBar: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(.blue)
            Text("Showing \(selectedHabitIDs.count) of \(allHabits.count) habits")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Clear") {
                selectedHabitIDs = Set(allHabits.map { $0.id })
                reloadWithCurrentFilters()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
    }
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Week number column
            Text("Week")
                .font(.caption2)
                .fontWeight(.semibold)
                .frame(width: 50)
                .foregroundColor(.secondary)
            
            // Day columns
            ForEach(weekdayHeaders, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func weekRowView(_ weekRow: WeekRow) -> some View {
        HStack(spacing: 4) {
            // Week number/year
            VStack(spacing: 2) {
                let weekComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: weekRow.weekStart)
                Text("W\(weekComponents.weekOfYear ?? 0)")
                    .font(.caption2)
                    .fontWeight(.medium)
                Text("\(weekComponents.yearForWeekOfYear ?? 0)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Days
            ForEach(weekRow.days) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 40)
    }
    
    private func dayCell(_ day: DayCompletion) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForCompletion(day.completionPercentage, hasData: day.hasData))
            
            // Show day number in lower left corner
            VStack {
                Spacer()
                HStack {
                    Text("\(calendar.component(.day, from: day.date))")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding([.leading, .bottom], 2)
                    Spacer()
                }
            }
            
            // Show month abbreviation for first day of month
            if calendar.component(.day, from: day.date) == 1 {
                Text(monthAbbreviation(for: day.date))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
            
            // Subtle border for today
            if calendar.isDateInToday(day.date) {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.blue, lineWidth: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func colorForCompletion(_ percentage: Int, hasData: Bool) -> Color {
        guard hasData && percentage > 0 else {
            return Color.gray.opacity(0.1)
        }
        
        switch percentage {
        case 1...25:
            return Color.orange.opacity(0.4)
        case 26...50:
            return Color.yellow.opacity(0.5)
        case 51...75:
            return Color.green.opacity(0.5)
        case 76...99:
            return Color.green.opacity(0.7)
        case 100:
            return Color.green.opacity(0.9)
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    private func monthAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    private func yearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private var habitFilterSheet: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { selectedHabitIDs.count == allHabits.count },
                        set: { isOn in
                            if isOn {
                                selectedHabitIDs = Set(allHabits.map { $0.id })
                            } else {
                                selectedHabitIDs.removeAll()
                            }
                        }
                    )) {
                        Text(selectedHabitIDs.count == allHabits.count ? "Deselect All" : "Select All")
                    }
                    .toggleStyle(CheckboxStyle(checkColor: .blue))
                }
                
                Section(header: Text("Habits")) {
                    ForEach(allHabits) { habit in
                        Toggle(isOn: Binding(
                            get: { selectedHabitIDs.contains(habit.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedHabitIDs.insert(habit.id)
                                } else {
                                    selectedHabitIDs.remove(habit.id)
                                }
                            }
                        )) {
                            Text(habit.title)
                        }
                        .toggleStyle(CheckboxStyle(checkColor: habit.getColor()))
                    }
                }
            }
            .navigationTitle("Filter Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showFilterSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        showFilterSheet = false
                        reloadWithCurrentFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func getWeekStart(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: date)) ?? date
    }
    
    private func loadAllHabits() {
        let habitsPredicate = #Predicate<HabitItem> { item in
            item.active
        }
        allHabits = (try? modelContext.fetch(FetchDescriptor<HabitItem>(predicate: habitsPredicate))) ?? []
        allHabits.sort { $0.title < $1.title }
        
        // Find the earliest habit creation date
        earliestHabitDate = allHabits.map { $0.timestamp }.min()
        
        // Initialize with all habits selected
        if selectedHabitIDs.isEmpty {
            selectedHabitIDs = Set(allHabits.map { $0.id })
        }
    }
    
    private func reloadWithCurrentFilters() {
        weekRows.removeAll()
        hasMoreData = true
        loadInitialWeeks()
    }
    
    private func loadInitialWeeks() {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Load only 4 weeks initially for instant display
        earliestDate = calendar.date(byAdding: .weekOfYear, value: -4, to: today) ?? today
        let initialEntries = fetchEntries(start: earliestDate, end: now, modelContext: modelContext)
        loadWeeks(from: today, weeksToLoad: 4, direction: .backward, preloadedEntries: initialEntries)
    }
    

    
    private func scheduleLoadMore() {
        // Cancel any pending load task
        loadTask?.cancel()
        
        // Schedule a new load after a short delay (debounce)
        loadTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                loadMoreWeeks()
            }
        }
    }
    
    private func loadMoreWeeks() {
        guard hasMoreData && !isLoadingMore else { return }
        
        // Check if we've already reached the earliest habit date
        if let earliest = earliestHabitDate {
            let earliestWeekStart = getWeekStart(for: earliest)
            if earliestDate <= earliestWeekStart {
                hasMoreData = false
                return
            }
        }
        
        isLoadingMore = true
        
        Task {
            // Load 12 more weeks
            let weeksToLoad = 12
            let fetchStart = calendar.date(byAdding: .weekOfYear, value: -weeksToLoad, to: earliestDate) ?? earliestDate
            let entries = fetchEntries(start: fetchStart, end: earliestDate, modelContext: modelContext)
            
            await MainActor.run {
                loadWeeks(from: earliestDate, weeksToLoad: weeksToLoad, direction: .backward, preloadedEntries: entries)
                earliestDate = fetchStart
                
                // Check again after loading
                if let earliest = earliestHabitDate {
                    let earliestWeekStart = getWeekStart(for: earliest)
                    if earliestDate <= earliestWeekStart {
                        hasMoreData = false
                    }
                }
                
                isLoadingMore = false
            }
        }
    }
    
    private enum LoadDirection {
        case forward, backward
    }
    
    private func loadWeeks(from startDate: Date, weeksToLoad: Int, direction: LoadDirection, preloadedEntries: [DailyEntry]? = nil) {
        var newWeekRows: [WeekRow] = []
        
        // Use cached habits
        let habits = allHabits
        
        // Determine date range to fetch
        let fetchStart: Date
        let fetchEnd: Date
        
        if direction == .backward {
            fetchEnd = startDate
            fetchStart = calendar.date(byAdding: .weekOfYear, value: -weeksToLoad, to: startDate) ?? startDate
        } else {
            fetchStart = startDate
            fetchEnd = calendar.date(byAdding: .weekOfYear, value: weeksToLoad, to: startDate) ?? startDate
        }
        
        // Use preloaded entries if available, otherwise fetch
        let entries = preloadedEntries ?? fetchEntries(start: fetchStart, end: fetchEnd, modelContext: modelContext)
        
        // Generate week rows
        for weekOffset in 0..<weeksToLoad {
            let weekStart: Date
            if direction == .backward {
                weekStart = calendar.date(byAdding: .weekOfYear, value: -(weeksToLoad - 1 - weekOffset), to: startDate) ?? startDate
            } else {
                weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate) ?? startDate
            }
            
            // Adjust to first day of week based on system settings
            let adjustedWeekStart = getWeekStart(for: weekStart)
            
            var days: [DayCompletion] = []
            
            for dayOffset in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: adjustedWeekStart) else { continue }
                
                // Don't show future dates
                if dayDate > Date() {
                    days.append(DayCompletion(date: dayDate, completionPercentage: 0, hasData: false))
                    continue
                }
                
                // Calculate completion percentage for this day across all habits
                let completion = calculateDayCompletion(for: dayDate, habits: habits, entries: entries)
                days.append(completion)
            }
            
            if !days.isEmpty {
                newWeekRows.append(WeekRow(weekStart: adjustedWeekStart, days: days))
            }
        }
        
        // Add to existing rows based on direction
        if direction == .backward {
            weekRows.append(contentsOf: newWeekRows)
        } else {
            weekRows.insert(contentsOf: newWeekRows, at: 0)
        }
        
        // Sort to ensure correct order (newest first)
        weekRows.sort { $0.weekStart > $1.weekStart }
    }
    
    private func calculateDayCompletion(for date: Date, habits: [HabitItem], entries: [DailyEntry]) -> DayCompletion {
        let weekday = HabitItem.Weekday(date: date)
        
        // Filter habits that should be tracked on this weekday, were created before this date, and are selected
        let relevantHabits = habits.filter { habit in
            habit.weekdays.contains(weekday) && 
            habit.timestamp <= date && 
            (selectedHabitIDs.isEmpty || selectedHabitIDs.contains(habit.id))
        }
        
        guard !relevantHabits.isEmpty else {
            return DayCompletion(date: date, completionPercentage: 0, hasData: false)
        }
        
        // Get entries for this day
        let dayEntries = entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date) &&
            relevantHabits.contains(where: { $0.id == entry.habitt.id })
        }
        
        guard !dayEntries.isEmpty else {
            return DayCompletion(date: date, completionPercentage: 0, hasData: true)
        }
        
        // Calculate completion percentage considering targetCount
        var totalTargetCount = 0
        var totalCompletedCount = 0
        
        for entry in dayEntries {
            let targetCount = entry.habitt.targetCount
            totalTargetCount += targetCount
            totalCompletedCount += min(entry.completionDates.count, targetCount)
        }
        
        let percentage = totalTargetCount > 0 ? (totalCompletedCount * 100) / totalTargetCount : 0
        
        return DayCompletion(date: date, completionPercentage: percentage, hasData: true)
    }
}

#Preview {
    CompactTimelineView()
        .modelContainer(ModelData.shared.modelContainer)
}
