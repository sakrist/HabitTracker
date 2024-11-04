//
//  CalendarView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 28/10/2024.
//

import SwiftUI



//struct WeeklyView: View {
//    let startDate: Date
//    @Environment(\.modelContext) private var modelContext
//    var calendar = Calendar.current
//    
//    var body: some View {
//        let weekDates = getWeekDates(from: startDate)
//        let entries = fetchEntries(start: weekDates.first!, end: weekDates.last!, modelContext: modelContext)
//        
//        HStack(spacing: 8) {
//            ForEach(weekDates, id: \.self) { date in
//                VStack {
//                    Text(shortDate(date))
//                    ProgressView(entries: entries, date: date)
//                }
//            }
//        }
//    }
//    
//    private func getWeekDates(from date: Date) -> [Date] {
//        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
//        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
//    }
//    
//    private func shortDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "E"
//        return formatter.string(from: date)
//    }
//}




struct ProgressView: View {
    let entries: [DailyEntry]
    let date: Date
    
    var body: some View {
        let weekday = HabitItem.Weekday(date: date)
        let todayEntries = entries.filter {
            $0.date.isSameDay(as: date) && $0.habit.weekdays.contains(weekday)
        }
        let completedEntries = todayEntries.filter { $0.isCompleted }
        let completionRatio = CGFloat(completedEntries.count) / CGFloat(max(todayEntries.count, 1))
        
        
        Circle()
            .fill(completionRatio > 0 ? Color.green : Color.red)
            .frame(width: 24, height: 24)
    }
}




struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedViewType: ViewType = .week
    
    enum ViewType {
        case week, month
    }
    
    @Environment(\.modelContext) private var modelContext
    private var calendar = Calendar.current

    var body: some View {
        NavigationSplitView {
            VStack {
                header
                Divider()
                
                Picker("View", selection: $selectedViewType) {
                    Text("Week").tag(ViewType.week)
                    Text("Month").tag(ViewType.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.leading)
            }
            
            if selectedViewType == .week {
                WeeklyView(startDate: currentDate)
            } else {
                MonthlyView(startDate: currentDate)
            }
            Spacer()
        } detail: {
            
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                currentDate = moveDate(-1)
            }) {
                Image(systemName: "chevron.left")
            }
            
            Text(dateString)
                .font(.title.bold())
            
            Button(action: {
                currentDate = moveDate(1)
            }) {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private func moveDate(_ offset: Int) -> Date {
        let component: Calendar.Component = selectedViewType == .week ? .weekOfYear : .month
        return calendar.date(byAdding: component, value: offset, to: currentDate) ?? currentDate
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        
        // Set the date style based on your view type
        if selectedViewType == .week {
            formatter.dateStyle = .long // For example, this could correspond to "MMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }

        return formatter.string(from: currentDate)
    }
}

//struct CalendarView: View {
//    let daysInMonth: Int = 30  // Adjust based on the month
//    let completionData: [Int]  // Completion level (0-5) for each day
//    
//    var body: some View {
//        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)  // 7 columns for the week
//        LazyVGrid(columns: columns, spacing: 8) {
//            ForEach(0..<daysInMonth, id: \.self) { day in
//                RoundedRectangle(cornerRadius: 4)
//                    .fill(gradientColor(for: completionData[day]))
//                    .frame(width: 24, height: 24)
//            }
//        }
//        .padding()
//    }
//    
//    private func gradientColor(for completion: Int) -> Color {
//        // Example gradient colors, adjust to match your design
//        let colors = [
//            Color.gray.opacity(0.1),
//            Color.green.opacity(0.3),
//            Color.green.opacity(0.5),
//            Color.green.opacity(0.7),
//            Color.green.opacity(0.9),
//            Color.green
//        ]
//        return colors[min(completion, colors.count - 1)]
//    }
//}


#Preview {
    CalendarView()
        .environment(ModelData())
        .modelContainer(SampleData.shared.modelContainer)
}
