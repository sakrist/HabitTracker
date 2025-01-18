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
    
    private var header: some View {
        HStack {
            Button(action: {
                date = moveDate(-1)
            }) {
                Image(systemName: "arrow.left")
            }
            
            Text(dateString)
                .font(.title.bold())
            
            Button(action: {
                date = moveDate(1)
            }) {
                Image(systemName: "arrow.right")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                header
                
                MonthlyView(startDate: date, habit: habit)
                
                Spacer()
            }
        }.navigationTitle("Habit: \(habit?.title ?? "")")

    }
    
    private func moveDate(_ offset: Int) -> Date {
        let component: Calendar.Component = .month
        return calendar.date(byAdding: component, value: offset, to: date) ?? date
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}


#Preview {
    HabitMonthView(date: Date(), habit: nil)
}
