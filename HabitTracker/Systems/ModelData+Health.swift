//
//  ModelData+Health.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 01/02/2025.
//

import Foundation
import HealthKit
import WidgetKit

extension ModelData {
    func process(_ samples: [HKSample]) {
        let entries = fetchHabitEntries(modelContext: modelContainer.mainContext, for: .now)
        
        // Group samples by their health type
        var completions: [HealthType: [Date]] = [:]
        
        for sample in samples {
            let healthType = extractHealthType(from: sample)
            if let type = healthType {
                completions[type, default: []].append(sample.endDate)
            }
        }
        
        for item in entries {
            if let healthType = item.habitt.healthType {
                if let dates = completions[healthType] {
                    // Add each completion date up to the target count
                    for date in dates.prefix(item.habitt.targetCount) {
                        if !item.completionDates.contains(date) {
                            item.completionDates.append(date)
                        }
                    }
                }
            }
        }
    }
    
    func process(_ samples: [HKSample], entry: DailyEntry) {
        // Group samples by their health type
        var completions: [HealthType: [Date]] = [:]
        
        for sample in samples {
            let healthType = extractHealthType(from: sample)
            if let type = healthType {
                completions[type, default: []].append(sample.endDate)
            }
        }
        
        if let healthType = entry.habitt.healthType {
            if let dates = completions[healthType] {
                // Add each completion date up to the target count
                for date in dates.prefix(entry.habitt.targetCount) {
                    if !entry.completionDates.contains(date) {
                        entry.completionDates.append(date)
                    }
                }
            }
        }
    }
    
    private func extractHealthType(from sample: HKSample) -> HealthType? {
        if sample.sampleType == HKObjectType.workoutType(),
           let workout = sample as? HKWorkout {
            return .workout(workout.workoutActivityType)
        } else if sample.sampleType == HKCategoryType(.mindfulSession) {
            return sample.sourceRevision.source.bundleIdentifier == "com.apple.journal"
                ? .category(.mindfulSession, .journal)
                : .category(.mindfulSession, .meditate)
        } else if sample.sampleType == HKCategoryType(.toothbrushingEvent) {
            return .category(.toothbrushingEvent)
        } else if sample.sampleType == HKQuantityType(.dietaryWater) {
            return .quantity(.dietaryWater)
        }
        return nil
    }
}


