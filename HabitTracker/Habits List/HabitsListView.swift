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

#if os(iOS)
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query var allitems: [HabitItem]
    @Query var progressEntries: [DailyEntry]
    
    @Query(filter: #Predicate<HabitItem> { item in
        item.active
    }) var items: [HabitItem]
    
    var sortedItems: [HabitItem] {
        items.sorted(by: sortHabits)
    }
    
    @State private var showExportActivityView = false
    @State private var showImportFilePicker = false
    
    @Binding var showAddHabit: Bool
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(sortedItems) { item in
                    NavigationLink(value: item) { // Use value-based navigation
                        HabitItemCell(item: item)
                            .contentShape(Rectangle())
                    }
                    .moveDisabled(item.isTimeSensitive)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItem)
            }
            .navigationDestination(for: HabitItem.self) { item in
                AddHabitView(habitItem: item)
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
                
                /*
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
                }*/
                
                ToolbarItem {
                    Button(action: {
                        showAddHabit = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .sheet(isPresented: $showAddHabit) {
                        AddHabitView()
                    }
                }
                
            }
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
        ModelData.shared.saveContext()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                sortedItems[index].active.toggle()
                
                cancelNotifications(baseIdentifier: sortedItems[index].id)
            }
        }
        ModelData.shared.saveContext()
    }
}


#Preview {
    HabitsListView(showAddHabit: .constant(false), navigationPath: .constant(.init()))
        .modelContainer(SampleData.shared.modelContainer)
}
