//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 06/10/2024.
//

import Foundation
import SwiftUI
import SwiftData
import ConfettiSwiftUI

struct HabitsList: View {
    
    let entries: [DailyEntry]
    
    @State private var counter: Int = 0
    
    var body: some View {
        List {
            ForEach(entries) { entry in
                HabitItemCell(item: entry.habit, entry: entry)
                    .onChange(of: entry.isCompleted) { old, newValue in
                        ModelData.shared.saveContext()
                        if (newValue) {
                            counter += 1
                        }
                    }
            }
        }
        .listStyle(.plain)
        .confettiCannon(trigger: $counter, num: 60, rainHeight: 100)
    }
}

struct DailyHabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date

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
                        Button(action: {
                            // navigate to Habits tab
                            selectedTab = 1
                        }) {
                            Text("Add habits")
                        }
                        Spacer()
                    } else {
                        HabitsList(entries: entries)
                    }
                }
                .onAppear {
                    entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    
}

#Preview {
    let model = ModelData.shared
    DailyHabitListView(selectedTab: .constant(0))
        .environment(ModelData.shared)
        .modelContainer(model.modelContainer)
}
