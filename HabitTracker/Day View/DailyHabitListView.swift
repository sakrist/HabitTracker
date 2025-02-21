//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 06/10/2024.
//

import Foundation
import SwiftUI
import SwiftData


struct DailyHabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    @Binding var showAddHabit: Bool
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    @State private var counter: Int = 0
    @State private var hasEarlyRecords: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Display the selected date
                if entries.count != 0 {
                    HStack {
                        if hasEarlyRecords {
                            Button(action: {
                                selectedDate = selectedDate.prevDay() ?? .now
                                fetchEntries()
                            }) {
                                Image(systemName: "chevron.left")
                            }
                        }
                        
                        
                        Text(selectedDate, style: .date)  // Show the current selected date
                            .font(.title.bold())
                            .frame(width: 270)
                        
                        if !selectedDate.isToday() {
                            Button(action: {
                                selectedDate = selectedDate.nextDay() ?? Date()
                                fetchEntries()
                            }) {
                                Image(systemName: "chevron.right")
                            }
                        } else {
                            Image(systemName: "chevron.right").opacity(0)
                        }
                    }
                    
                }

                VStack {
                    if (entries.count == 0) {
                        NoHabitsYet(selectedTab: $selectedTab, showAddHabit: $showAddHabit)
                    } else {
                        DayHabitsListView(date: $selectedDate, entries: entries)
                    }
                }
                .onAppear {
                    fetchEntries()
                }
            }
        }.onReceive(notificationPublisher) { _ in
            // check if selected date is the same
            selectedDate = Date()
            fetchEntries()
        }.refreshable {
            self.entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
            Health.shared.updateHabits(entries: self.entries, for: selectedDate)
            
        }.gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        // Swipe Left - Move Forward
                        if (!selectedDate.isToday()) {
                            selectedDate = selectedDate.nextDay()!
                            fetchEntries()
                        }
                    } else if value.translation.width > threshold {
                        // Swipe Right - Move Backward
                        if (hasEarlyRecords) {
                            selectedDate = selectedDate.prevDay()!
                            fetchEntries()
                        }
                    }
                }
        )
        
    }
    
    func fetchEntries() {
        Task {
            self.entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
            
            let entriesDayBefore = fetchHabitEntries(modelContext: modelContext, for: selectedDate.prevDay() ?? .now)
            hasEarlyRecords = entriesDayBefore.count > 0
        }
    }
    
    private var notificationPublisher: NotificationCenter.Publisher {
        #if canImport(UIKit)
        return NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        #elseif canImport(AppKit)
        return NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        #else
        fatalError("Unsupported platform")
        #endif
    }
    
}

#Preview {
    let model = ModelData.shared
    DailyHabitListView(selectedTab: .constant(0), showAddHabit: .constant(false))
        .environment(ModelData.shared)
        .modelContainer(model.modelContainer)
}
