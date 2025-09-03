//
//  ModelData.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/10/2024.
//

import SwiftData
import CoreData
import Foundation
import SwiftUI
import WidgetKit
import os

typealias SchemaLatest = SchemaV4

typealias HabitItem = SchemaLatest.HabitItem
typealias HabitCategory = SchemaLatest.HabitCategory
typealias DailyEntry = SchemaLatest.DailyEntry

var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "model")

@MainActor
@Observable
class ModelData {
    static let shared = ModelData()
    static let undoManager = UndoManager()
        
    var notificationsEnabled: Bool = false
    
    var modelContainer: ModelContainer
    
    convenience init() {
        
        let schema = Schema(versionedSchema: SchemaLatest.self)
        let modelConfiguration = ModelConfiguration(schema: schema,
                                                    isStoredInMemoryOnly: false,
                                                    groupContainer: .automatic,
                                                    cloudKitDatabase: .automatic)
        
        do {
            let container = try ModelContainer(for: schema, migrationPlan: MigrationPlanToLatest.self,
                                             configurations: [modelConfiguration])
            container.mainContext.undoManager = ModelData.undoManager
            self.init(container: container)
        } catch {
            do {
                let container = try ModelContainer(for: schema, migrationPlan: nil,
                                                 configurations: [modelConfiguration])
                container.mainContext.undoManager = ModelData.undoManager
                self.init(container: container)
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
    }
    
    init(container: ModelContainer) {
        self.modelContainer = container
        self.modelContainer.mainContext.undoManager = ModelData.undoManager
        insertCategories()
    }
    
    func saveContext() {
        do {
            try modelContainer.mainContext.save()  // Explicitly save the changes to the modelContext
        } catch {
            logger.error("Error saving model context: \(error)")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        logger.log("Saved context and reloaded widgets")
    }
    
    var firstLaunch: Bool {
        get {
            return !UserDefaults.standard.bool(forKey: "NotFirstLaunch")
        }
        set {
            UserDefaults.standard.set(!newValue, forKey: "NotFirstLaunch")
        }
    }
    
    // MARK: - Data Synchronization
    
    // Notification name for data changes
    static let dataChangedNotification = Notification.Name("com.sakrist.HabitTracker.DataChanged")
    
    func refreshData() {
        // Force a sync with CloudKit
        modelContainer.mainContext.processPendingChanges()
        
        do {
            try modelContainer.mainContext.save()
            // Post notification that data has changed
            NotificationCenter.default.post(name: ModelData.dataChangedNotification, object: nil)
        } catch {
            logger.error("Error saving context during refresh: \(error.localizedDescription)")
        }
    }

}
