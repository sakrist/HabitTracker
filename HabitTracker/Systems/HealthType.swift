//
//  HealthType.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 02/02/2025.
//


import HealthKit

enum HealthType : CaseIterable, Identifiable, Codable {
    
    case none
    case workout(HKWorkoutActivityType)
    case category(HKCategoryTypeIdentifier, _ subtype: SubType = .no)
    case quantity(HKQuantityTypeIdentifier)
    
    enum SubType: String, Codable {
        case no
        case meditate
        case journal
    }
    
    // Computed ID for Identifiable conformance
    var id: String {
        switch self {
        case .none:
            return "none"
        case .workout(let type):
            return "workout_\(type.rawValue)"
        case .category(let type, let subtype):
            return "category_\(type.rawValue)_\(subtype.rawValue)"
        case .quantity(let type):
            return "quantity_\(type.rawValue)"
        }
    }

    // Manually providing allCases for CaseIterable conformance
    static let allCases: [HealthType] = [
        .none,
        .workout(.cycling),
        .workout(.running),
        .workout(.walking),
        .workout(.swimming),
        .workout(.traditionalStrengthTraining),
        .workout(.crossTraining),
        .workout(.yoga),
        .workout(.hiking),
        .workout(.pilates),
        .category(.toothbrushingEvent),
        .category(.mindfulSession, .meditate),
        .category(.mindfulSession, .journal),
        .quantity(.dietaryWater)
    ]
    
    func sampleType() -> HKSampleType? {
        switch self {
        case .none:
            return nil
        case .workout:
            return HKObjectType.workoutType()
        case .category(let identifier, _):
            return HKObjectType.categoryType(forIdentifier: identifier)
        case .quantity(let identifier):
            return HKObjectType.quantityType(forIdentifier: identifier)
        }
    }
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the encodedType to know what type we are dealing with
        let encodedType = try container.decode(Int.self, forKey: .encodedType)
        
        switch encodedType {
        case 0: // none
            self = .none
            
        case 1: // workout
            let rawValue = try container.decode(UInt.self, forKey: .value)
            if let activityType = HKWorkoutActivityType(rawValue: rawValue) {
                self = .workout(activityType)
            } else {
                throw DecodingError.dataCorrupted(
                                    .init(codingPath: container.codingPath, debugDescription: "Invalid HKWorkoutActivityType raw value.")
                                )
            }
        case 2: // category
            let rawValue = try container.decode(String.self, forKey: .value)
            let subtype = try container.decode(SubType.self, forKey: .subtype)
            let categoryType = HKCategoryTypeIdentifier(rawValue: rawValue)
            self = .category(categoryType, subtype)
            
        case 3: // quantity
            let rawValue = try container.decode(String.self, forKey: .value)
            let quantityType = HKQuantityTypeIdentifier(rawValue: rawValue)
            self = .quantity(quantityType)
        default:
            throw DecodingError.dataCorrupted(
                                .init(codingPath: container.codingPath, debugDescription: "Unknown encodedType.")
                            )
        }
    }
    
    // Encode the HealthType to an Encoder
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .none:
            try container.encode(0, forKey: .encodedType)
            try container.encodeNil(forKey: .value)
            
        case .workout(let activityType):
            try container.encode(1, forKey: .encodedType)
            try container.encode(activityType.rawValue, forKey: .value)
            
        case .category(let categoryType, let subtype):
            try container.encode(2, forKey: .encodedType)
            try container.encode(categoryType.rawValue, forKey: .value)
            try container.encode(subtype, forKey: .subtype)
            
        case .quantity(let quantityType):
            try container.encode(3, forKey: .encodedType)
            try container.encode(quantityType.rawValue, forKey: .value)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case encodedType
        case value
        case subtype
    }
    
    static func == (lhs: HealthType, rhs: HealthType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.workout(a), .workout(b)):
            return a == b
        case let (.category(a, subA), .category(b, subB)):
            return a == b && subA == subB
        case let (.quantity(a), .quantity(b)):
            return a == b
        default:
            return false
        }
    }
    
    static func != (lhs: HealthType, rhs: HealthType) -> Bool {
        return !(lhs == rhs)
    }
    
    static func != (lhs: HealthType?, rhs: HealthType) -> Bool {
        if let lhs = lhs {
            return !(lhs == rhs)
        }
        return false
    }
    
    static func fromID(_ id: String) -> HealthType {
        let components = id.split(separator: "_", maxSplits: 2).map { String($0) }
        
        guard components.count >= 2 else {
            return id == "none" ? .none : .none
        }
        
        let type = components[0]
        let value = components[1]
        let subtype = components.count == 3 ? components[2] : nil
        
        switch type {
        case "workout":
            if let intValue = UInt(value), let workoutType = HKWorkoutActivityType(rawValue: intValue) {
                return .workout(workoutType)
            }
        case "category":
            if let subtype = subtype {
                return .category(HKCategoryTypeIdentifier(rawValue: value), SubType(rawValue: subtype) ?? .no)
            } else {
                return .category(HKCategoryTypeIdentifier(rawValue: value), .no) // Default to .other if no valid subtype is found
            }
        case "quantity":
            return .quantity(HKQuantityTypeIdentifier(rawValue: value))
        default:
            break
        }
        
        return .none
    }
}
