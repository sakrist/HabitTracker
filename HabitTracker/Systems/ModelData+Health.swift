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
        
        var completed: [HealthType] = []
        
        for sample in samples {
            if (sample.sampleType == HKObjectType.workoutType()) {
                if let workout = sample as? HKWorkout {
                    completed.append(.workout(workout.workoutActivityType))
                }
            } else if sample.sampleType == HKCategoryType.init(.mindfulSession) {
                if sample.sourceRevision.source.name == "Journal" {
                    completed.append(.category(.mindfulSession, .journal))
                } else {
                    completed.append(.category(.mindfulSession, .meditate))
                }
            } else if sample.sampleType == HKCategoryType.init(.toothbrushingEvent) {
                completed.append(.category(.toothbrushingEvent))
            } else if sample.sampleType == HKQuantityType.init(.dietaryWater) {
                completed.append(.quantity(.dietaryWater))
            }

#if DEBUG
            print(sample.startDate)
            print(sample.endDate)
            print("type \(sample.sampleType)")
            print(sample.metadata ?? "")
            print(sample.sourceRevision.source.name)
#endif
            //                    print("Mindfulness session: \(sample)")
        }
        
        for item in entries {
            if let healthType = item.habit.healthType {
                if completed.contains(where: { $0 == healthType }) {
                    item.setCompleted(true)
                }
            }
        }
    }
    
    func process(_ samples: [HKSample], entry: DailyEntry) {
        
        var completed: [HealthType] = []
        
        for sample in samples {
            if (sample.sampleType == HKObjectType.workoutType()) {
                if let workout = sample as? HKWorkout {
                    completed.append(.workout(workout.workoutActivityType))
                }
            } else if sample.sampleType == HKCategoryType.init(.mindfulSession) {
                if sample.sourceRevision.source.name == "Journal" {
                    completed.append(.category(.mindfulSession, .journal))
                } else {
                    completed.append(.category(.mindfulSession, .meditate))
                }
            } else if sample.sampleType == HKCategoryType.init(.toothbrushingEvent) {
                completed.append(.category(.toothbrushingEvent))
            } else if sample.sampleType == HKQuantityType.init(.dietaryWater) {
                completed.append(.quantity(.dietaryWater))
            }

#if DEBUG
            print(sample.startDate)
            print(sample.endDate)
            print("type \(sample.sampleType)")
            print(sample.metadata)
            print(sample.sourceRevision.source.name)
#endif
            //                    print("Mindfulness session: \(sample)")
        }
        
        if let healthType = entry.habit.healthType {
            if completed.contains(where: { $0 == healthType }) {
                entry.setCompleted(true)
            }
        }
    }
}


