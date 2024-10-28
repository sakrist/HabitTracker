//
//  HabitsList.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 27/09/2024.
//

import Foundation
import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<HabitItem> { item in
        item.active
    }) var items: [HabitItem]
    
    func customSort(item1: HabitItem, item2: HabitItem) -> Bool {
        if item1.isTimeSensitive != item2.isTimeSensitive {
            return item1.isTimeSensitive // Time-sensitive items come first
        }
        
        if let time1 = item1.time, let time2 = item2.time {
            // Both times are non-nil; compare directly
            if time1 != time2 {
                return time1 < time2
            }
        } else if item1.time != nil {
            // item1 has a time, item2 does not; item1 should come first
            return true
        } else if item2.time != nil {
            // item2 has a time, item1 does not; item2 should come first
            return false
        }
        
        // If times are equal or both are nil, fall back to order
        return item1.order < item2.order
    }
    
    var sortedItems: [HabitItem] {
        items.sorted(by: customSort)
    }
    
    @State private var showingAddHabitView = false
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sortedItems) { item in
                    NavigationLink(destination: AddHabitView(habitItem: item)) {
                        HabitItemCell(item: item)
                    }
                    .moveDisabled(item.isTimeSensitive)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItem)
            }
            .navigationTitle("Habits")
            .listStyle(.plain)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: {
                        showingAddHabitView = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .sheet(isPresented: $showingAddHabitView) {
                        AddHabitView()
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    // Handle reordering
    private func moveItem(from source: IndexSet, to destination: Int) {
        var copyItems = sortedItems
        copyItems.move(fromOffsets: source, toOffset: destination)
    
        var index:Int = 0
        for item in copyItems {
            item.order = index
            index += 1
        }
        try? modelContext.save()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                sortedItems[index].active.toggle()
            }
        }
    }
}


#Preview {
    HabitsListView()
        .modelContainer(SampleData.shared.modelContainer)
}
