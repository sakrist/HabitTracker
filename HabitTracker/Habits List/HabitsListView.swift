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


struct LoadingOverlay: View {
    var message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .shadow(radius: 10)
        }
    }
}

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
    @State private var showImportSuccessAlert = false
    @State private var showImportFailureAlert = false
    @State private var showImportOptions = false
    @State private var importURL: URL? = nil
    
    @State private var showHealthUpdateConfirmation = false
    @State private var isUpdatingHealth = false
    @State private var healthUpdateProgress = "Preparing to update health data..."
    @State private var showHealthUpdateSuccessAlert = false
    
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
            .navigationTitle("Habits List")
            .listStyle(.plain)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                
                ToolbarItem {
                    Button(action: {
                        showExportActivityView = true
                    }) {
                        Label("Export", systemImage: "arrow.up.circle")
                    }
                    .sheet(isPresented: $showExportActivityView) {
                        if let fileURL = ExportImportData.shared.exportHabits() {
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
                                // Store URL
                                importURL = url
                                
                                // Check if there are any existing habits
                                let hasExistingHabits = !items.isEmpty
                                
                                if hasExistingHabits {
                                    // If we have habits, show options dialog
                                    showImportOptions = true
                                } else {
                                    // If no habits, import directly (nothing to merge with)
                                    importData(replace: false)
                                }
                            case .failure(let error):
                                print("Failed to import habits: \(error)")
                                showImportFailureAlert = true
                            }
                        }
                    )
                    .confirmationDialog(
                        "Import Options",
                        isPresented: $showImportOptions,
                        titleVisibility: .visible
                    ) {
                        Button("Merge with existing data") {
                            importData(replace: false)
                        }
                        
                        Button("Replace all existing data", role: .destructive) {
                            importData(replace: true)
                        }
                        
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Do you want to merge with your existing data or replace everything?")
                    }
                    .alert("Import Successful", isPresented: $showImportSuccessAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Your habits have been imported successfully.")
                    }
                    .alert("Import Failed", isPresented: $showImportFailureAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("There was an error importing your habits. Please try again.")
                    }
                }
                
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
                
#if os(iOS)
                ToolbarItem() {
                    EditButton()
                }
#endif
                
                ToolbarItem {
                    Button(action: {
                        showHealthUpdateConfirmation = true
                    }) {
                        Label("Update HealthKit Habits", systemImage: "heart")
                    }
                    .alert("Update Health Data", isPresented: $showHealthUpdateConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Update") {
                            updateHealthData()
                        }
                    } message: {
                        Text("This will update all habits with the latest health data from Apple Health. This may take a moment.")
                    }
                }
                
            }
            .alert("Update Complete", isPresented: $showHealthUpdateSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All habits have been updated with the latest health data.")
            }
            .overlay(
                Group {
                    if isUpdatingHealth {
                        LoadingOverlay(message: healthUpdateProgress)
                            .allowsHitTesting(true)
                    }
                }
            )
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
                sortedItems[index].deactivate()
                
                cancelNotifications(baseIdentifier: sortedItems[index].id)
            }
        }
        ModelData.shared.saveContext()
    }
    
    private func updateHealthData() {
        isUpdatingHealth = true
        
        Task {
            // Get all entries, not just today
            let allEntries = fetchAllHabitEntries(modelContext: modelContext)
            
            await MainActor.run {
                healthUpdateProgress = "Fetching data from Apple Health..."
            }
            
            // Process in chunks to keep UI responsive
            let chunkSize = 50
            for i in stride(from: 0, to: allEntries.count, by: chunkSize) {
                let chunk = Array(allEntries[i..<min(i + chunkSize, allEntries.count)])
                
                await MainActor.run {
                    healthUpdateProgress = "Updating \(i+1) to \(min(i + chunkSize, allEntries.count)) of \(allEntries.count) entries..."
                }
                
                // Update health data for this chunk
                await Health.shared.updateHabits(entries: chunk)
                
                // Small delay to allow UI updates
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            await MainActor.run {
                isUpdatingHealth = false
                showHealthUpdateSuccessAlert = true
            }
        }
    }
    
    private func importData(replace: Bool) {
        guard let url = importURL else {
            showImportFailureAlert = true
            return
        }
        
        // Start file access
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access the selected file")
            showImportFailureAlert = true
            return
        }
        
        Task {
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Create a secure bookmarked copy
            do {
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(
                    "import_\(UUID().uuidString).json"
                )
                
                try FileManager.default.copyItem(at: url, to: tempFileURL)
                
                let completed: Bool
                if replace {
                    completed = await ExportImportData.shared.replaceAllWithImport(from: tempFileURL)
                } else {
                    completed = await ExportImportData.shared.importHabits(from: tempFileURL)
                }
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempFileURL)
                
                if completed {
                    showImportSuccessAlert = true
                } else {
                    showImportFailureAlert = true
                }
            } catch {
                print("Import error: \(error.localizedDescription)")
                showImportFailureAlert = true
            }
        }
    }
    

}


#Preview {
    HabitsListView(showAddHabit: .constant(false), navigationPath: .constant(.init()))
        .modelContainer(SampleData.shared.modelContainer)
}
