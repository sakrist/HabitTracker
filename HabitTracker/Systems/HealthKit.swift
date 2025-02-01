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
    
    let supportedSport: [String: HKWorkoutActivityType] = [
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
    
    let supportedCategory: [String: HKCategoryTypeIdentifier] = [
        "Tooth brushing": .toothbrushingEvent,
        "Meditate": .mindfulSession,
        "Journal": .mindfulSession
    ]
    
    func fullList() -> [String] {
        Array(supportedSport.keys) + Array(supportedCategory.keys)
    }
    
    func activityObject(for name: String) -> HKSampleType? {
        if (supportedCategory.keys.contains(name)) {
            if let type = supportedCategory[name] {
                return HKObjectType.categoryType(forIdentifier: type)
            }
        }
        if (supportedSport.keys.contains(name)) {
            return HKObjectType.workoutType()
        }
        return nil
    }
    
    
    func isSupported(_ name:String) -> Bool {
        supportedSport.keys.contains(name) || supportedCategory.keys.contains(name)
    }
    
    
    func available() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    
    func isHabitAuthroised(title:String) -> HKAuthorizationStatus {
        if let type = supportedCategory[title] {
            if let object = HKObjectType.categoryType(forIdentifier: type) {
                return healthStore.authorizationStatus(for: object)
            }
        } else if supportedSport.keys.contains(title) {
            return healthStore.authorizationStatus(for: HKObjectType.workoutType())
        }
        return .notDetermined
    }
    
//    func isHabitAuthroised2(title:String) async -> HKAuthorizationRequestStatus {
//        if let type = supportedCategory[title] {
//            if let object = HKObjectType.categoryType(forIdentifier: type) {
//                do {
//                    return try await healthStore.statusForAuthorizationRequest(toShare: [], read: [object])
//                } catch {
//                    
//                }
//            }
//        }
//        return .unknown
//    }
    
    
    func requestHabitAuthroisation(title:String, completion: @escaping (Bool) -> Void) {
        if let type = supportedCategory[title] {
            if let object = HKObjectType.categoryType(forIdentifier: type) {
                healthStore.requestAuthorization(toShare: [object], read: [object]) { success, error in
                    completion(success)
                }
            }
        } else if (supportedSport.keys.contains(title)) {
            
        } else {
            completion(false)
        }
    }
    
    // MARK: --
    
    func enableHabitBackgroundDelivery(habit:HabitItem, completion: @escaping (Bool) -> Void) {
        if let type = supportedCategory[habit.title] {
            guard let object = HKObjectType.categoryType(forIdentifier: type) else {
                print("Category type \(type.rawValue) is not available")
                completion(false)
                return
            }
            enablBackgroundDelivery(object, completion: completion)
        } else if (supportedSport.keys.contains(habit.title)) {
            enablBackgroundDelivery(HKObjectType.workoutType(), completion: completion)
        } else {
            completion(false)
        }
    }
    
    func disableHabitBackgroundDelivery(habit:HabitItem) {
        if let type = supportedCategory[habit.title] {
            guard let object = HKObjectType.categoryType(forIdentifier: type) else {
                print("Category type \(type.rawValue) is not available")
                return
            }
            disableBackgroundDelivery(object)
        }
    }
    
    
    func enablBackgroundDelivery(_ object: HKSampleType, completion: @escaping (Bool) -> Void) {
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
    
    func disableBackgroundDelivery(_ object: HKSampleType) {
        Task {
            try? await healthStore.disableBackgroundDelivery(for: object)
        }
    }
    
    func setupObserverQuery(_ type: HKSampleType) {
        
        let query = HKObserverQuery(sampleType: type, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            
            // Fetch new mindfulness data
            self.query(type: type)
            
            // Signal that the background task is complete
            completionHandler()
        }
        
        healthStore.execute(query)
    }
    
    func query(type: HKSampleType) {
        let today = Self.datePredicate()
        let descriptor = HKQueryDescriptor(sampleType:type, predicate: today)
        
        let query = HKSampleQuery(queryDescriptors: [descriptor],
                                  limit: HKObjectQueryNoLimit
        ) { query, samples, error in
            if let samples = samples {
                self.process(samples)
            }
        }
        
        healthStore.execute(query)
    }
    
    func query(type: HKSampleType, predicate:NSPredicate = datePredicate(), completion: @escaping ([HKSample]) -> Void) {
        let descriptor = HKQueryDescriptor(sampleType:type, predicate: predicate)
        
        let query = HKSampleQuery(queryDescriptors: [descriptor],
                                  limit: HKObjectQueryNoLimit
        ) { query, samples, error in
            completion(samples ?? [])
        }
        
        healthStore.execute(query)
    }
    
    class func datePredicate(date:Date = Date()) -> NSPredicate {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let end = date.isToday() ? .now : Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        return HKQuery.predicateForSamples(withStart: startOfDay, end: end)
    }
    
    // MARK:  --- process sample
    
    func process(_ samples: [HKSample]) {
//        Task {
//            let entries = fetchHabitEntries(modelContext: ModelData.shared.modelContainer.mainContext, for: .now)
//        }
    }
    
}


