//
//  HabitMonthVIew.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 16/01/2025.
//

import SwiftUI


struct HabitDetailProgressView : View {
    @State var date: Date
    let habit: HabitItem
    @Environment(\.modelContext) private var modelContext
    var calendar = Calendar.current
    
    @State var streak: Int = 0
    @State var completionRate: Int = 0
    @State var longest: Int = 0
    @State var total: Int = 0
    
    private var monthSelector: some View {
        HStack {
            
            if (!habit.timestamp.isSameMonth(date: date)) {
                Button(action: {
                    date = moveDate(-1)
                    updateProgress()
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            
            Text(dateString)
                .font(.title2.bold())
                .frame(width: 250)
            
            if !date.isCurrentMonth() {
                Button(action: {
                    date = moveDate(1)
                    updateProgress()
                }) {
                    Image(systemName: "chevron.right")
                }
            } else {
                Image(systemName: "chevron.right").opacity(0)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    
                    VStack {
                        monthSelector
                        Divider()
                        MonthlyView(startDate: date, habit: habit)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 3)
                    
                    
                    ProgressCardView(currentStreak: streak,
                                     completionRate: completionRate)
                    .padding(.vertical, 3)
                    
                    
                    HStack {
                        // Current Streak Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Longest Streak")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(longest) days")
                                .font(.title3.bold())
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Completion Rate Section
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Days")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(total)")
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 3)
                    
                    Spacer()
                }
            }
        }.navigationTitle("Habit: \(habit.title)")
            .onAppear() {
                updateProgress()
            }
    }
    
    private func updateProgress() {
        Task {
            (streak, completionRate, longest, total) = ModelData.shared.calculateStreak(habit: habit, for: date)
        }
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


struct Preview_HabitMonthView : View {
    
    @State var isLinkActive = false

    var body: some View {
        let entries = fetchHabitEntries(modelContext: ModelData.shared.modelContainer.mainContext, for: Date())
        TabView() {
            NavigationView {
                VStack {
                    
                    NavigationLink(destination: HabitDetailProgressView(date: Date(), habit:entries[0].habitt), isActive: $isLinkActive
                    ) {
                        // Button to activate the NavigationLink
                        Button("Go to Detail View") {
                            isLinkActive = true
                        }
                    }
                }
            }
        }.onAppear {
            isLinkActive = true
        }
    }
}
 

#Preview {
//    HabitMonthView(date: Date(), habit: nil)
    Preview_HabitMonthView()
}
