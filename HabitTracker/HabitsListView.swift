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
    @Query private var items: [HabitItem]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    HabitItemCell(item: item)
                }
                .onDelete(perform: deleteItems)
            }.listStyle(.plain)
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
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = HabitItem(title: "New habit", color: .blue, timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}


#Preview {
    HabitsListView()
        .modelContainer(SampleData.shared.modelContainer)
}
