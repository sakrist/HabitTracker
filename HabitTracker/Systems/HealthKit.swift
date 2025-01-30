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
    
    let supportedSportActivities: [String: HKWorkoutActivityType] = [
        "Cycling": .cycling,
        "Running": .running,
        "Walking": .walking,
        "Swimming": .swimming,
        "Strength Training": .traditionalStrengthTraining,
        "Cross Training": .crossTraining,
        "Yoga": .yoga,
        "Hiking": .hiking,
        "Pilates": .pilates,
    ]
    
    let supportedActivities: [String: HKCategoryTypeIdentifier] = [
        "Teeth brushing": .toothbrushingEvent,
        "Meditate": .mindfulSession,
        "Journal": .mindfulSession
    ]
    
    func isSupported(_ name:String) -> Bool {
        supportedSportActivities.keys.contains(name) || supportedActivities.keys.contains(name)
    }
    
    
    func available() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    
    func isHabitAuthroised(title:String) -> HKAuthorizationStatus {
        if let type = supportedActivities[title] {
            if let object = HKObjectType.categoryType(forIdentifier: type) {
                return healthStore.authorizationStatus(for: object)
            }
        }
        return .notDetermined
    }
    
    func isHabitAuthroised2(title:String) async -> HKAuthorizationRequestStatus {
        if let type = supportedActivities[title] {
            if let object = HKObjectType.categoryType(forIdentifier: type) {
                do {
                    return try await healthStore.statusForAuthorizationRequest(toShare: [], read: [object])
                } catch {
                    
                }
            }
        }
        return .unknown
    }
    
    
    
    
    
    func requestHabitAuthroisation(title:String, completion: @escaping (Bool) -> Void) {
        if let type = supportedActivities[title] {
            if let object = HKObjectType.categoryType(forIdentifier: type) {
                healthStore.requestAuthorization(toShare: nil, read: [object]) { success, error in
                    completion(success)
                }
            }
        }
    }
    
    // MARK: --
    
    func enableHabitBackgroundDelivery(habit:HabitItem, completion: @escaping (Bool) -> Void) {
        if let type = supportedActivities[habit.title] {
            enablBackgroundDelivery(type, completion: completion)
        }
    }
    
    func disableHabitBackgroundDelivery(habit:HabitItem) {
        if let type = supportedActivities[habit.title] {
            disableBackgroundDelivery(type)
        }
    }
    
    
    func enablBackgroundDelivery(_ identifier: HKCategoryTypeIdentifier, completion: @escaping (Bool) -> Void) {
        guard let object = HKObjectType.categoryType(forIdentifier: identifier) else {
            print("Category type \(identifier.rawValue) is not available")
            completion(false)
            return
        }
        
        healthStore.enableBackgroundDelivery(for: object, frequency: .immediate) { success, error in
            if success {
                self.setupObserverQuery(object)
                completion(true)
            } else if let error = error {
                print("Error enabling background delivery: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func disableBackgroundDelivery(_ identifier: HKCategoryTypeIdentifier) {
        Task {
            guard let object = HKObjectType.categoryType(forIdentifier: identifier) else {
                print("Category type \(identifier.rawValue) is not available")
                return
            }
            try? await healthStore.disableBackgroundDelivery(for: object)
        }
    }
    
    func setupObserverQuery(_ type: HKCategoryType) {

        let query = HKObserverQuery(sampleType: type, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }

            // Fetch new mindfulness data
            self.fetchSessions(type: type)

            // Signal that the background task is complete
            completionHandler()
        }

        healthStore.execute(query)
    }

    func fetchSessions(type: HKCategoryType) {
        let today = todayPredicate()
        let descriptor = HKQueryDescriptor(sampleType:type, predicate: today)
        
        let query = HKSampleQuery(queryDescriptors: [descriptor],
            limit: HKObjectQueryNoLimit
        ) { query, samples, error in
            if let samples = samples as? [HKCategorySample] {
                for sample in samples {
                    
                    print(sample.sourceRevision.source.name)
                    
//                    print("Mindfulness session: \(sample)")
                }
            }
        }

        healthStore.execute(query)
    }
    
    private func todayPredicate() -> NSPredicate {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: startOfDay, end: .now)
    }
    
    // MARK:  --- sport
    
//    private func enableWorkoutBackgroundDelivery() {
//        healthStore.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .immediate) { success, error in
//            if success {
//                print("Background delivery enabled for workouts")
//            } else if let error = error {
//                print("Error enabling background delivery: \(error.localizedDescription)")
//            }
//        }
//    }
    
//    private func setupWorkoutObserverQuery() {
//        
//        let predicate = NSPredicate(format: "workoutActivityType IN %@", [
//                    HKWorkoutActivityType.pilates.rawValue,
//                    HKWorkoutActivityType.yoga.rawValue
//                ])
//
//        let query = HKObserverQuery(sampleType: HKObjectType.workoutType(), predicate: nil) { _, completionHandler, error in
//            if let error = error {
//                print("Observer query error: \(error.localizedDescription)")
//                return
//            }
//
//            self.fetchWorkouts()
//            completionHandler()
//        }
//
//        healthStore.execute(query)
//    }
    
}


