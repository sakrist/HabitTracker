//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 06/10/2024.
//

import Foundation
import SwiftUI
import SwiftData
import RainbowUI

struct MainListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    @Binding var selectedTab: Int
    @Binding var showAddHabit: Bool
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    @State private var counter: Int = 0
    @State private var hasEarlyRecords: Bool = true
    
    @Binding var navigationPath: NavigationPath
    
    // Calculate progress for the day considering targetCount
    private var dayProgress: Double {
        guard !entries.isEmpty else { return 0 }
        
        var totalTargetCount = 0
        var totalCompletedCount = 0
        
        for entry in entries {
            let targetCount = entry.habit?.targetCount ?? 1
            totalTargetCount += targetCount
            totalCompletedCount += min(entry.completionDates.count, targetCount)
        }
        
        return totalTargetCount > 0 ? Double(totalCompletedCount) / Double(totalTargetCount) : 0
    }
    
    // Check if we have at least one completion
    private var hasCompletions: Bool {
        return entries.contains { !$0.completionDates.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Display the selected date
                if entries.count != 0 {
                    HStack {
                        if hasEarlyRecords {
                            Button(action: {
                                selectedDate = selectedDate.prevDay()
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
                                selectedDate = selectedDate.nextDay()
                                fetchEntries()
                            }) {
                                Image(systemName: "chevron.right")
                            }
                        } else {
                            Image(systemName: "chevron.right").opacity(0)
                        }
                    }
                    
                    // Progress bar - only show when at least one habit has completions
                    if hasCompletions {
                        HStack {
                            ProgressView(value: dayProgress)
                                .progressViewStyle(.linear)
                                .frame(height: 4) // Make it slim
                                .padding(.horizontal)
                            
                                Text("\(Int(dayProgress * 100))%")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal)
//                        .animation(.easeInOut, value: dayProgress)
                    }
                }

                VStack {
                    DayHabitsListView(date: $selectedDate, entries: entries)
                    
                    if(entries.count == 0) {
                        VStack {
                            // show button add habits which will navigate to Habits tab
                            Text("Start by adding habits you already do daily.\n")
                            Button {
                                // navigate to Habits tab
                                selectedTab = 1
                                showAddHabit = true
                            } label: {
                                Text("Add Habits")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .font(.title)
                            .buttonStyle(RainbowButtonStyle())
                            Spacer()
                        }
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
            await Health.shared.updateHabits(entries: self.entries)
            
        }.gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        // Swipe Left - Move Forward
                        if (!selectedDate.isToday()) {
                            selectedDate = selectedDate.nextDay()
                            fetchEntries()
                        }
                    } else if value.translation.width > threshold {
                        // Swipe Right - Move Backward
                        if (hasEarlyRecords) {
                            selectedDate = selectedDate.prevDay()
                            fetchEntries()
                        }
                    }
                }
        ).withUndoRedo {
            // Refresh entries after undo
            self.entries = fetchHabitEntries(modelContext: ModelData.shared.modelContainer.mainContext , for: selectedDate)
        }
        
    }
    
    func fetchEntries() {
        Task {
            self.entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
            
            let entriesDayBefore = fetchHabitEntries(modelContext: modelContext, for: selectedDate.prevDay())
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
    MainListView(selectedTab: .constant(0),
                 showAddHabit: .constant(false),
                 navigationPath: .constant(.init()))
        .environment(ModelData.shared)
        .modelContainer(model.modelContainer)
}
