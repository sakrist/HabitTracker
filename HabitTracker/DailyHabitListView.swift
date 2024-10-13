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

                List {
                    ForEach(entries) { entry in
                        HabitItemCell(item: entry.habit, entry: entry)
                    }
                }
                .listStyle(.plain)
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
    let model = ModelData()
    DailyHabitListView()
        .environment(model)
        .modelContainer(model.modelContainer)
}
