//
//  HabitMonthVIew.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 16/01/2025.
//

import SwiftUI


struct HabitMonthView : View {
    @State var date: Date
    let habit: HabitItem?
    @Environment(\.modelContext) private var modelContext
    var calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? Date()
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    
                    Spacer()
                    
                    Text("\(monthDate(date))")  // Show the current selected date
                        .font(.title.bold())
                        .frame(width: 150)
                    
                    Spacer()
                    
                    Button(action: {
                        date = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? Date()
                    }) {
                        Image(systemName: "arrow.right")
                    }
                    Spacer()
                }
                
                MonthlyView(startDate: date, habit: habit)
                
                Spacer()
            }
        }.navigationTitle("Habit: \(habit?.title ?? "")")

    }
    
    private func monthDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM" // Display day of the month
        return formatter.string(from: date)
    }
}


#Preview {
    HabitMonthView(date: Date(), habit: nil)
}
