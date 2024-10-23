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
    }, sort: \HabitItem.order) var items: [HabitItem]
    
    @State private var showingAddHabitView = false
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink(destination: AddHabitView(habitItem: item)) {
                        HabitItemCell(item: item)
                    }
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
        var copyItems = items
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
                items[index].active.toggle()
            }
        }
    }
}


#Preview {
    HabitsListView()
        .modelContainer(SampleData.shared.modelContainer)
}
