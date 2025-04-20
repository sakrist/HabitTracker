//
//  HealthKit.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//

import SwiftUI
import HealthKit
import WidgetKit

class Health {
    
    static let customHabitName = "custom_habit"
    
    static let shared = Health()
    let healthStore = HKHealthStore()
    
    // Replace the array with templates using healthType directly
    let activityTemplates: [HealthActivityTemplate] = [
        // None template for custom habits
        HealthActivityTemplate(
            healthType: .none,
            icon: "pencil",
            defaultColor: Color.gray.toHex()
        ),
        
        // Workouts
        HealthActivityTemplate(
            healthType: .workout(.cycling),
            icon: "bicycle",
            defaultColor: Color.blue.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.running),
            icon: "figure.run",
            defaultColor: Color.blue.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.walking),
            icon: "figure.walk",
            defaultColor: Color.mint.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.swimming),
            icon: "figure.pool.swim",
            defaultColor: Color.cyan.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.traditionalStrengthTraining),
            icon: "dumbbell.fill",
            defaultColor: Color.red.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.crossTraining),
            icon: "figure.mixed.cardio",
            defaultColor: Color.orange.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.yoga),
            icon: "figure.yoga",
            defaultColor: Color.purple.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.hiking),
            icon: "mountain.2.fill",
            defaultColor: Color.green.toHex()
        ),
        HealthActivityTemplate(
            healthType: .workout(.pilates),
            icon: "figure.mind.and.body",
            defaultColor: Color.indigo.toHex()
        ),

        // Category-Based Activities
        HealthActivityTemplate(
            healthType: .category(.toothbrushingEvent),
            icon: "mouth.fill",
            defaultColor: Color.mint.toHex()
        ),
        HealthActivityTemplate(
            healthType: .category(.mindfulSession, .meditate),
            icon: "brain.head.profile",
            defaultColor: Color.purple.toHex()
        ),
        HealthActivityTemplate(
            healthType: .category(.mindfulSession, .journal),
            icon: "text.book.closed.fill",
            defaultColor: Color.orange.toHex()
        ),

        // Quantity-Based Activities
        HealthActivityTemplate(
            healthType: .quantity(.dietaryWater),
            icon: "drop.fill",
            defaultColor: Color.cyan.toHex()
        )
    ]
    
    // Helper method to find template by health type ID
    func findTemplate(byTypeId id: String) -> HealthActivityTemplate? {
        return activityTemplates.first { $0.id == id }
    }
    
    // Helper method to find template by health type
    func findTemplate(byHealthType healthType: HealthType) -> HealthActivityTemplate? {
        return activityTemplates.first { $0.healthType == healthType }
    }
    
    func fullList() -> [HealthActivityTemplate] {
        return activityTemplates
    }
    
    func activityObject(for typeId: String) -> HKSampleType? {
        guard let template = findTemplate(byTypeId: typeId),
              template.healthType != .none else { 
            return nil 
        }
        
        switch template.healthType {
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
    
    func isSupported(_ name: String) -> Bool {
        activityTemplates.contains { $0.id == name }
    }
    
    func available() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func isHabitAuthroised(typeId: String) -> HKAuthorizationStatus {
        if let object = activityObject(for: typeId) {
            return healthStore.authorizationStatus(for: object)
        }
        return .notDetermined
    }
    
    func requestHabitAuthroisation(typeId: String, completion: @escaping (Bool) -> Void) {
        if let object = activityObject(for: typeId) {
            healthStore.requestAuthorization(toShare: [object], read: [object]) { success, error in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    // New method to request authorization for multiple health types at once
    func requestBulkHealthAuthorization(for habits: [HabitItem], completion: @escaping (Bool) -> Void) {
        // Collect all unique health types that need authorization
        var typesToAuthorize = Set<HKSampleType>()
        
        for habit in habits {
            if let healthType = habit.healthType, healthType != .none,
               let sampleType = activityObject(for: healthType.id) {
                typesToAuthorize.insert(sampleType)
            }
        }
        
        // If no health types, return early
        if typesToAuthorize.isEmpty {
            completion(true)
            return
        }
        
        // Request authorization for all types at once
        healthStore.requestAuthorization(toShare: typesToAuthorize, read: typesToAuthorize) { success, error in
            if let error = error {
                print("Health authorization error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // New method to check if a habit has health authorization
    func verifyHealthAuthorization(for habit: HabitItem) -> Bool {
        guard let healthType = habit.healthType, 
              healthType != .none,
              let sampleType = activityObject(for: healthType.id) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: sampleType)
        return status == .sharingAuthorized
    }
    
    // MARK: --
    
    func enableHabitBackgroundDelivery(habit: HabitItem, completion: @escaping (Bool) -> Void) {
        if let typeId = habit.hType,
           let object = activityObject(for: typeId) {
            enablBackgroundDelivery(object, completion: completion)
        } else {
            completion(false)
        }
    }
    
    func disableHabitBackgroundDelivery(habit: HabitItem) {
        // TODO: dont disable for sport
        if let _ = activityObject(for: habit.title) {
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
            if let healthType = entry.habitt.healthType, healthType != .none {
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


