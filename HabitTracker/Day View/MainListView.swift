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
    
    @State private var selectedDate: Date = Date()  // The currently selected date
                                          
    @State private var entries: [DailyEntry] = []
    
    @State private var counter: Int = 0
    @State private var hasEarlyRecords: Bool = true
    
    @Binding var navigationPath: NavigationPath
    
    @State private var showShareSheet = false
    @State private var markdownText: String = ""

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
        NavigationStack(path: $navigationPath) {
            VStack {
                // Display the selected date
                if entries.count != 0 {
                    HStack {
                        if hasEarlyRecords {
                            Button(action: {
                                selectedDate = selectedDate.prevDay()
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
                    DayHabitsListView(date: selectedDate)
                    
                    if entries.isEmpty {
                        VStack {
                            // Show button to add habits
                            Text("Start by adding habits you already do daily.\n")
                            Button {
                                // Navigate to Habits tab
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
        }
        .onReceive(notificationPublisher) { _ in
            // Check if selected date is the same
            selectedDate = Date()
        }
        .refreshable {
            await Health.shared.updateHabits(entries: self.entries)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        // Swipe Left - Move Forward
                        if !selectedDate.isToday() {
                            selectedDate = selectedDate.nextDay()
                        }
                    } else if value.translation.width > threshold {
                        // Swipe Right - Move Backward
                        if hasEarlyRecords {
                            selectedDate = selectedDate.prevDay()
                        }
                    }
                }
        )
        .gesture(
            LongPressGesture()
                .onEnded { _ in
                    showShareSheet = true
                }
        )
        .sheet(isPresented: $showShareSheet) {
            if let text = generateMarkdown() {
                #if os(iOS)
                ActivityView(activityItems: [text])
                #else
                ShareLink(item: markdownText)
                #endif
            }
        }.onChange(of: selectedDate) { _, newValue in
            fetchEntries()
        }
    }

    func fetchEntries() {
        Task {
            // this line would also generate habits for today
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
    
    private func generateMarkdown() -> String? {
        var markdown = "# Habit Entries for \(selectedDate.formatted(date: .complete, time: .omitted))\n\n"
        if entries.isEmpty {
            markdown += "No entries for this day.\n"
        } else {
            for entry in entries {
                let habitTitle = entry.habit?.title ?? "Unknown Habit"
                let completionTimes = entry.completionDates.map { $0.formatted(date: .omitted, time: .shortened) }.joined(separator: ", ")
                markdown += "- [\(entry.isCompleted ? "*" : "")] \(habitTitle) - \(completionTimes.isEmpty ? "" : completionTimes)\n"
            }
        }
        return markdown
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
