//
//  WeeklyView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 03/11/2024.
//
import SwiftUI

struct WeeklyView: View {
    let startDate: Date
    @Environment(\.modelContext) private var modelContext
    var calendar = Calendar.current
    
//    var body: some View {
//        let (weekStart, weekEnd) = getWeekDates(from: startDate)
//        let entries = fetchEntries(start: weekStart, end: weekEnd, modelContext: modelContext)
//                
//        HStack(spacing: 12) {
//            ForEach(weekStart.days(in: weekEnd), id: \.self) { date in
//                VStack {
//                    CircularProgressView(entries: entries, date: date)
//                    Text(shortDate(date))
//                }
//            }
//        }
//    }
    
    var body: some View {
        let (weekStart, weekEnd) = getWeekDates(from: startDate)
        let entries = fetchEntries(start: weekStart, end: weekEnd, modelContext: modelContext)
        
        VStack(spacing: 16) {
            

            // Create a grid of days
            let weekDays = getDatesInWeek(from: weekStart)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 10) {
                ForEach(weekDays, id: \.self) { date in
                    let completionRate = completionPercentage(for: date, in: entries)
                    let color = colorForCompletionRate(completionRate)
                    
                    VStack {
                        Text(shortDate(date))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Rectangle()
                            .fill(color)
                            .frame(height: 50) // Fixed height for heatmap
                            .cornerRadius(8)
                        
                        Text("\(completionRate)%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(5)
                }
            }
            .padding()
        }
    }
    
    private func getWeekDates(from date: Date) -> (start: Date, end: Date) {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return (Date(), Date()) }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)?.addingTimeInterval(86399) // End of Sunday
        return (weekStart, weekEnd!)
    }
    
    private func getDatesInWeek(from startDate: Date) -> [Date] {
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Display abbreviated day name
        return formatter.string(from: date)
    }

    private func completionPercentage(for date: Date, in entries: [DailyEntry]) -> Int {
        let todayEntries = entries.filter { $0.date.isSameDay(as: date) }
        let completedEntries = entries.filter { $0.date.isSameDay(as: date) && $0.isCompleted }
        return todayEntries.isEmpty ? 0 : (completedEntries.count * 100) / todayEntries.count
    }
    
    private func colorForCompletionRate(_ rate: Int) -> Color {
        switch rate {
        case 0: return Color.gray.opacity(0.2)
        case 1...33: return Color.red.opacity(0.5)
        case 34...66: return Color.yellow.opacity(0.5)
        case 67...100: return Color.green.opacity(0.5)
        default: return Color.clear
        }
    }
}


//#Preview {
//    WeeklyView()
//        .environment(ModelData())
//        .modelContainer(SampleData.shared.modelContainer)
//}
