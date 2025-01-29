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

typealias SchemaLatest = SchemaV2

typealias HabitItem = SchemaLatest.HabitItem
typealias HabitCategory = SchemaLatest.HabitCategory
typealias DailyEntry = SchemaLatest.DailyEntry


@MainActor
@Observable
class ModelData {
    static let shared = ModelData()
        
    var notificationsEnabled: Bool = false
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema(versionedSchema: SchemaLatest.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, migrationPlan: nil, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
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
    
    // MARK: -- configure

}

// MARK: Migration Plan V1 to V2

enum MigrationPlanV1toV2: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    // MARK: Migration Stages
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            print("migrateV1toV2.willMigrate()")
        },
        didMigrate: { context in
            print("migrateV1toV2.didMigrate()")
            
            let habits = try context.fetch(FetchDescriptor<SchemaV2.HabitItem>())
            print("migrateV1toV2 - found \(habits.count) animals")
            
            // default all animals to not extinct
            for item in habits {
                item.trackingType = .manual
            }

            try context.save()
        }
    )
}

