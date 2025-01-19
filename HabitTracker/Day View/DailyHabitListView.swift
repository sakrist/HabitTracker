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
        NavigationSplitView {
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
                        // show button add habits which will navigate to Habits tab
                        Spacer()
                        Text("Start by adding habits you already do daily.\n")
                        
                        Text(" · · · ")
                        
                        Text("If you want to build a new habits, \nstart by adding one habit at a time.\n")
                            .multilineTextAlignment(.center)
                        
                        // 3 dots
                        Text(" · · · ")
                        
                        Text("Science says - \nit takes around 66 days to make a habit stick.\n")
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // navigate to Habits tab
                            selectedTab = 1
                        }) {
                            Text("Add habits")
                        }
                        Spacer()
                        Spacer()
                    } else {
                        HabitsList(date: selectedDate, entries: entries)
                    }
                }
                .onAppear {
                    entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                }
            }
        } detail: {
            Text("Select an item")
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
