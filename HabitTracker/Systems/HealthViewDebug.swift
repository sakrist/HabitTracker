//
//  HealthViewDebug.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 29/01/2025.
//


import SwiftUI
import HealthKit

struct HealthViewDebug: View {
    

    @State private var selectedCategory: String = "Journal"
    
    var body: some View {
        VStack {
            Text("Debug HealthView")
            let categories: [String] = Health.shared.fullList()
            Picker("Health records", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            
            Button("sessions") {
                if let object = Health.shared.activityObject(for: selectedCategory) {
//                    let date = Calendar.current.date(byAdding: .day, value: -1, to: .now)
                    Health.shared.query(type: object, predicate: Health.datePredicate(date: .now)) { samples in
                        
                        ModelData.shared.process(samples)
//                            for sample in samples {
//
//                                if (sample.sampleType == HKObjectType.workoutType()) {
//                                    if let workout = sample as? HKWorkout {
//                                        print("Workout Activity Type: \(workout.workoutActivityType.rawValue)")
//                                    }
//                                }
//                                print(sample.startDate)
//                                print(sample.endDate)
//                                print("type \(sample.sampleType)")
//                                print(sample.metadata)
//                                print(sample.sourceRevision.source.name)
//                                
//                                //                    print("Mindfulness session: \(sample)")
//                            }
                    }
                }
            }
        }
    }
}

#Preview {
    HealthViewDebug()
}
