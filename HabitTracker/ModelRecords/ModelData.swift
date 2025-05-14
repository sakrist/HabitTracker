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

typealias SchemaLatest = SchemaV4

typealias HabitItem = SchemaLatest.HabitItem
typealias HabitCategory = SchemaLatest.HabitCategory
typealias DailyEntry = SchemaLatest.DailyEntry


@MainActor
@Observable
class ModelData {
    static let shared = ModelData()
    static let undoManager = UndoManager()
        
    var notificationsEnabled: Bool = false
    
    var modelContainer: ModelContainer
    
    convenience init() {
        let schema = Schema(versionedSchema: SchemaLatest.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
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
            print("Error saving model context: \(error)")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var firstLaunch: Bool {
        get {
            return !UserDefaults.standard.bool(forKey: "NotFirstLaunch")
        }
        set {
            UserDefaults.standard.set(!newValue, forKey: "NotFirstLaunch")
        }
    }
    // MARK: -- configure

}

// MARK: Migration Plans


enum MigrationPlanToLatest: SchemaMigrationPlan {
    // Store completion dates during migration
    private static var storedCompletionDates: [String: Date] = [:]
    
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV3.self, SchemaV4.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV3toV4]
    }
    
    // MARK: Migration Stages
    
    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: { context in
            print("Starting migration from V3 to V4")
            // Store completion dates before migration
            let entries = try context.fetch(FetchDescriptor<SchemaV3.DailyEntry>())
            print("Found \(entries.count) entries to store dates")
            for entry in entries {
                if let completionDate = entry.completionDate {
                    // Use habit.id + date as unique key
                    let key = "\(entry.habit.id)_\(entry.date.timeIntervalSince1970)"
                    storedCompletionDates[key] = completionDate
                }
            }
            print("Stored \(storedCompletionDates.count) completion dates")
        },
        didMigrate: { context in
            do {
                // Migrate habits first
                let habits = try context.fetch(FetchDescriptor<SchemaV4.HabitItem>())
                print("Found \(habits.count) habits to migrate")
                for item in habits {
                    item.targetCount = 1
                }
                
                // Migrate entries with stored completion dates
                let entries = try context.fetch(FetchDescriptor<SchemaV4.DailyEntry>())
                print("Found \(entries.count) entries to migrate")
                for item in entries {
                    let key = "\(item.habitt.id)_\(item.date.timeIntervalSince1970)"
                    if let storedDate = storedCompletionDates[key] {
                        item.completionDates = [storedDate]
                    }
                    item.achievement = Achievement.none
                }
                
                // Clear stored dates
                storedCompletionDates.removeAll()
                
                try context.save()
                print("Migration completed successfully")
            } catch {
                print("Migration failed: \(error)")
                storedCompletionDates.removeAll()
                throw error
            }
        }
    )
}

enum RollbackMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV3.self, SchemaV4.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV4toV3]
    }
    
    // MARK: Migration Stages
    
    static let migrateV4toV3 = MigrationStage.custom(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: nil
    )
}
