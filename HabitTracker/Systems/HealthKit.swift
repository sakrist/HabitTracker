//
//  HealthKit.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//

import HealthKit

// https://github.com/christophhagen/HealthKitExtensions.git  - try

class Health {
    static let shared = Health()
    let healthStore = HKHealthStore()
    
    func requestHealth(complete: @escaping (Bool) -> Void) async {
        
        var allTypes: Set<HKObjectType> = [
            HKQuantityType.workoutType(),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceWheelchair),
            HKQuantityType(.dietaryWater),
        ]
        
        if let toothbrushingType = HKObjectType.categoryType(forIdentifier: .toothbrushingEvent) {
            allTypes.insert(toothbrushingType)
        }
        
        if let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            allTypes.insert(mindfulnessType)
        }
        
        do {
            // Check that Health data is available on the device.
            if HKHealthStore.isHealthDataAvailable() {
                
                // Asynchronously request authorization to the data.
                try await healthStore.requestAuthorization(toShare: [], read: allTypes)
            }
        } catch {
            
            // Typically, authorization requests only fail if you haven't set the
            // usage and share descriptions in your app's Info.plist, or if
            // Health data isn't available on the current device.
            print("*** An unexpected error occurred while requesting authorization: \(error.localizedDescription) ***")
            complete(false)
            return
        }
        complete(true)
    }
    
    func enableMindfulnessBackgroundDelivery() {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("Mindfulness type is not available")
            return
        }

        healthStore.enableBackgroundDelivery(for: mindfulnessType, frequency: .immediate) { success, error in
            if success {
                print("Background delivery enabled for mindfulness sessions")
            } else if let error = error {
                print("Error enabling background delivery: \(error.localizedDescription)")
            }
        }
    }
    
    func setupMindfulnessObserverQuery() {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("Mindfulness type is not available")
            return
        }

        let query = HKObserverQuery(sampleType: mindfulnessType, predicate: nil) { _, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }

            // Fetch new mindfulness data
            self.fetchMindfulnessSessions()

            // Signal that the background task is complete
            completionHandler()
        }

        healthStore.execute(query)
    }

    func fetchMindfulnessSessions() {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }

        let query = HKSampleQuery(
            sampleType: mindfulnessType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { query, samples, error in
            if let error = error {
                print("Error fetching mindfulness sessions: \(error.localizedDescription)")
            } else if let samples = samples as? [HKCategorySample] {
                for sample in samples {
                    print("Mindfulness session: \(sample)")
                }
            }
        }

        healthStore.execute(query)
    }
    
}


