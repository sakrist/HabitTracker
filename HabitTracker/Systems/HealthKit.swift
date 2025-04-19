//
//  HealthKit.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//

import HealthKit
import WidgetKit

class Health {
    
    static let customHabitName = "Custom Habit"
    
    static let shared = Health()
    let healthStore = HKHealthStore()
    
    let supportedHabits: [String: HealthType] = [
        customHabitName : .none,
        
        // Workouts
        "Cycling": .workout(.cycling),
        "Running": .workout(.running),
        "Walking": .workout(.walking),
        "Swimming": .workout(.swimming),
        "Strength Training": .workout(.traditionalStrengthTraining),
        "Cross Training": .workout(.crossTraining),
        "Yoga": .workout(.yoga),
        "Hiking": .workout(.hiking),
        "Pilates": .workout(.pilates),

        // Category-Based Activities
        "Tooth brushing": .category(.toothbrushingEvent),
        "Meditation": .category(.mindfulSession, .meditate),
        "Journaling": .category(.mindfulSession, .journal),

        // Quantity-Based Activities
        "Water Intake": .quantity(.dietaryWater)
    ]
    
    func fullList() -> [String] {
        Array(supportedHabits.keys)
    }
    
    
    func activityObject(for name: String) -> HKSampleType? {
        guard let habitType = supportedHabits[name] else { return nil }
        
        switch habitType {
        case .none:
            return nil
        case .workout(_):
            return HKObjectType.workoutType()

        case .category(let type, _):
            return HKObjectType.categoryType(forIdentifier: type)

        case .quantity(let type):
            return HKObjectType.quantityType(forIdentifier: type)
        }
    }
    
    
    func isSupported(_ name:String) -> Bool {
        supportedHabits.keys.contains(name)
    }
    
    
    func available() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    
    func isHabitAuthroised(title:String) -> HKAuthorizationStatus {
        if let object = activityObject(for: title) {
            return healthStore.authorizationStatus(for: object)
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

        if let object = activityObject(for: title) {
            healthStore.requestAuthorization(toShare: [object], read: [object]) { success, error in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: --
    
    func enableHabitBackgroundDelivery(habit:HabitItem, completion: @escaping (Bool) -> Void) {
        if let object = activityObject(for: habit.title) {
            enablBackgroundDelivery(object, completion: completion)
        } else {
            completion(false)
        }
    }
    
    func disableHabitBackgroundDelivery(habit:HabitItem) {
        // TODO: dont disable for sport
        if let object = activityObject(for: habit.title) {
//            disableBackgroundDelivery(object)
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
                Task {
                    await ModelData.shared.process(samples)
                }
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
        let end = date.isToday() ? .now : startOfDay.nextDay()
        return HKQuery.predicateForSamples(withStart: startOfDay, end: end)
    }
    
    // MARK:  --- process sample
    
    @MainActor
    func updateHabits(entries: [DailyEntry]) async {
        for entry in entries {
            if let healthType = entry.habit.healthType, healthType != .none {
                if let type = healthType.sampleType() {
                    query(type: type, predicate: Health.datePredicate(date: entry.date)) { samples in
                        ModelData.shared.process(samples, entry:entry)
                    }
                }
            }
        }
        ModelData.shared.saveContext()
    }
}


