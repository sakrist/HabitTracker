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
    
    
    var body: some View {
//        NavigationStack(path: $navigationPath) {
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
                    
                }

                VStack {
                    DayHabitsListView(date: $selectedDate, entries: entries)
                    
                    if(entries.count == 0 || modelData.firstLaunch) {
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
        )
        
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
