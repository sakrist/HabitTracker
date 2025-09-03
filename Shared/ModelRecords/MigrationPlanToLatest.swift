//
//  MigrationPlanToLatest.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 03/09/2025.
//
import Foundation
import SwiftData

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
            logger.log("Starting migration from V3 to V4")
            // Store completion dates before migration
            let entries = try context.fetch(FetchDescriptor<SchemaV3.DailyEntry>())
            logger.log("Found \(entries.count) entries to store dates")
            for entry in entries {
                if let completionDate = entry.completionDate {
                    // Use habit.id + date as unique key
                    let key = "\(entry.habit.id)_\(entry.date.timeIntervalSince1970)"
                    storedCompletionDates[key] = completionDate
                }
            }
            logger.log("Stored \(storedCompletionDates.count) completion dates")
        },
        didMigrate: { context in
            do {
                // Migrate habits first
                let habits = try context.fetch(FetchDescriptor<SchemaV4.HabitItem>())
                logger.log("Found \(habits.count) habits to migrate")
                for item in habits {
                    item.targetCount = 1
                }
                
                // Migrate entries with stored completion dates
                let entries = try context.fetch(FetchDescriptor<SchemaV4.DailyEntry>())
                logger.log("Found \(entries.count) entries to migrate")
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
                logger.log("Migration completed successfully")
            } catch {
                logger.error("Migration failed: \(error)")
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
