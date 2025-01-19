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
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date
    
    @State private var counter: Int = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Display the selected date
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                        entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    
                    Spacer()
                    
                    Text(selectedDate, style: .date)  // Show the current selected date
                        .font(.title.bold())
                    
                    Spacer()
                    
                    if !selectedDate.isToday() {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                            entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                        }) {
                            Image(systemName: "arrow.right")
                        }
                    } else {
                        Image(systemName: "arrow.right").opacity(0)
                    }
                }
                .padding()

                VStack {
                    if (entries.count == 0) {
                        NoHabitsYet(selectedTab: $selectedTab)
                    } else {
                        HabitsList(date: selectedDate, entries: entries)
                    }
                }
                .onAppear {
                    entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                }
            }
        }.onReceive(notificationPublisher) { _ in
            // check if selected date is the same
            selectedDate = Date()
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
    DailyHabitListView(selectedTab: .constant(0))
        .environment(ModelData.shared)
        .modelContainer(model.modelContainer)
}
