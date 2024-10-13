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
    
    @State private var items: [HabitItem] = []
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
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
                }
            }
        } detail: {
            Text("Select an item")
        }.onAppear {
            items = fetchActiveHabits(modelContext: modelContext)
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = HabitItem(title: "New habit", color: .blue, timestamp: Date())
            modelContext.insert(newItem)
            items.append(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                items[index].active.toggle()
            }
            items.remove(atOffsets: offsets)
        }
    }
}


#Preview {
    HabitsListView()
        .modelContainer(SampleData.shared.modelContainer)
}
