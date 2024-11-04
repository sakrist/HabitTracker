//
//  HabitsList.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 27/09/2024.
//

import Foundation
import SwiftUI
import SwiftData

import UniformTypeIdentifiers


struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query var allitems: [HabitItem]
    
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
    @State private var showExportActivityView = false
    @State private var showImportFilePicker = false
    
    
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
                        showExportActivityView = true
                    }) {
                        Label("Export", systemImage: "arrow.up.circle")
                    }.sheet(isPresented: $showExportActivityView) {
                        if let fileURL = exportHabits() {
                            ActivityView(activityItems: [fileURL])
                        }
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        showImportFilePicker = true
                    }) {
                        Label("Import", systemImage: "arrow.down.circle")
                    }
                    .fileImporter(
                        isPresented: $showImportFilePicker,
                        allowedContentTypes: [.json],
                        onCompletion: { result in
                            switch result {
                            case .success(let url):
                                importHabits(from: url)
                            case .failure(let error):
                                print("Failed to import habits: \(error)")
                            }
                        }
                    )
                }
                
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
    
    func exportHabits() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(allitems)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("HabitData.json")
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            print("Error exporting habits: \(error)")
            return nil
        }
    }
    
    func importHabits(from url: URL) {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedHabits = try decoder.decode([HabitItem].self, from: jsonData)
            
            // Add imported habits to your existing collection (e.g., SwiftData context)
            for habit in importedHabits {
                // Assuming you have a method to add these to SwiftData or your model context
                // modelContext.insert(habit)
            }
        } catch {
            print("Error importing habits: \(error)")
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
