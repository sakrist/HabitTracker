//
//  MonthlyView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 03/11/2024.
//
import SwiftUI

struct MonthlyView: View {
    let startDate: Date
    let habit: HabitItem?
    @Environment(\.modelContext) private var modelContext
    var calendar = Calendar.current

    var body: some View {
        let daysInMonth = getDaysInMonth(from: startDate)
        let entries = fetchEntries(start: monthStart(), end: monthEnd(), habit:habit, modelContext: modelContext)

        // Create a grid of days
        let columns = Array(repeating: GridItem(.flexible(minimum: 30, maximum: 40), spacing: 4), count: 7)

        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(HabitItem.Weekday.allCases, id: \.self) { weekday in
                Text(weekday.abbreviatedName)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .frame(height: 15)
                    .multilineTextAlignment(.center)
            }
            
            // Add empty spaces for alignment if the first day doesn't start on the calendar's first weekday
            ForEach(0..<getWeekdayShift(from: daysInMonth.first!), id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 30)
            }

            ForEach(daysInMonth, id: \.self) { date in
                let completionRate = completionPercentage(for: date, in: entries)
                let color = colorForCompletionRate(completionRate)
                
                VStack {
                    Rectangle()
                        .fill(color)
                        .frame(height: 30) // Smaller height for squares
                        .cornerRadius(6)
                    
                    Text(shortDate(date))
                        .font(.caption)
                        .frame(height: 15) // Ensure consistent height for labels
                }
                .padding(3) // Padding around each item
            }
        }
        .padding()
    }

    private func getDaysInMonth(from date: Date) -> [Date] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        return range.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
    }

    private func getWeekdayShift(from date: Date) -> Int {
            let weekdayIndex = calendar.component(.weekday, from: date)
            return (weekdayIndex - calendar.firstWeekday + 7) % 7
        }
    
    private func monthStart() -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
    }

    private func monthEnd() -> Date {
        calendar.date(byAdding: .month, value: 1, to: monthStart())!.addingTimeInterval(-1) // End of the month
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Display day of the month
        return formatter.string(from: date)
    }

    private func completionPercentage(for date: Date, in entries: [DailyEntry]) -> Int {
        let weekday = HabitItem.Weekday(date: date)
        let todayEntries = entries.filter {
            $0.date.isSameDay(as: date) && $0.habit.weekdays.contains(weekday)
        }
        let completedEntries = todayEntries.filter { $0.isCompleted }
        
        return todayEntries.isEmpty ? 0 : (completedEntries.count * 100) / todayEntries.count
    }

    private func colorForCompletionRate(_ rate: Int) -> Color {
        switch rate {
        case 0: return Color.gray.opacity(0.2)
        case 1...33: return Color.red.opacity(0.5)
        case 34...66: return Color.yellow.opacity(0.5)
        case 67...100: return Color.green.opacity(0.7)
        default: return Color.clear
        }
    }
}

#Preview {
    MonthlyView(startDate: Date(), habit: nil)
        .modelContainer(ModelData.shared.modelContainer)
}
