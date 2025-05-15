//
//  SchemaV4.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 02/02/2025.
//

import SwiftData
import Foundation

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SchemaV4.HabitItem.self, SchemaV4.HabitCategory.self, SchemaV4.DailyEntry.self]
    }
}

extension SchemaV4 {
    @Model
    final class HabitItem : Codable {
        var id: String = UUID().uuidString
        var title: String = ""
        var color: String = "#0000FF"
        
        @Relationship(inverse: \HabitCategory.habits)
        var category: HabitCategory?
        var time: Date?
        var note: String = ""
        var weekdays: Set<HabitItem.Weekday> = Set(HabitItem.Weekday.allCases)
        
        var order: Int = 0
        var timestamp: Date = Date()// created date
        var deactivated: Date?
        var active: Bool = true
        
        var hType: String? = "none" // health data and fitness
        var targetCount: Int = 1  // Default to 1 completion per day
        
        @Relationship(inverse: \DailyEntry.habit)
        var entries: [DailyEntry]? = []
    
        enum Weekday: Int, CaseIterable, Identifiable, Codable {
            
            var id: Int { rawValue }
            
            case monday, tuesday, wednesday, thursday, friday, saturday, sunday
            
            // Mapping string names to each weekday case
            private static let weekdayMapping: [String: Weekday] = {
                // Use localized weekday names to create the mapping
                let calendar = Calendar.current
                let weekdays = calendar.weekdaySymbols.map { $0.lowercased() }
                return [
                    weekdays[0]: .sunday,    // Sunday
                    weekdays[1]: .monday,    // Monday
                    weekdays[2]: .tuesday,   // Tuesday
                    weekdays[3]: .wednesday, // Wednesday
                    weekdays[4]: .thursday,  // Thursday
                    weekdays[5]: .friday,    // Friday
                    weekdays[6]: .saturday    // Saturday
                ]
            }()
            
            // Initializer that uses the mapping dictionary
            init(date: Date) {
                let weekdayIndex = Calendar.current.component(.weekday, from: date) - 1 // Get index (0-6)
                let weekdayName = Calendar.current.weekdaySymbols[weekdayIndex].lowercased()
                self = Weekday.weekdayMapping[weekdayName] ?? .sunday // Default to Sunday if not found
            }
            
            var displayName: String {
                switch self {
                case .monday: return "M"
                case .tuesday: return "T"
                case .wednesday: return "W"
                case .thursday: return "T"
                case .friday: return "F"
                case .saturday: return "S"
                case .sunday: return "S"
                }
            }
            
            /// Returns a localized abbreviated name for the weekday
            var abbreviatedName: String {
                let calendar = Calendar.current
                let formatter = DateFormatter()
                formatter.locale = Locale.current // Use the device's current locale
                formatter.dateFormat = "E" // Abbreviated weekday format
                
                // Find the first date in the week corresponding to this weekday
                let weekdayIndex = rawValue + 2 // Weekday indices start from 1 (Sunday) in Calendar
                let date = calendar.date(from: DateComponents(weekday: weekdayIndex)) ?? Date()
                return formatter.string(from: date)
            }
        }
        
        // Custom CodingKeys to handle encoding/decoding if needed
        private enum CodingKeys: String, CodingKey {
            case id, title, color, category, time, note, weekdays, order, timestamp, active, healthType, targetCount
        }
        
        
        init(id: String = UUID().uuidString,
             title: String,
             color: String = "#0000FF",
             category: HabitCategory?,
             time: Date? = nil, // time for reminder
             note: String = "",
             weekdays: Set<Weekday> = [],
             order: Int = 0,
             timestamp: Date = Date(), // date when created habit
             active: Bool = true,
             hType: String? = "none",
             targetCount: Int = 1) {
            self.id = id
            self.title = title
            self.color = color
            self.category = category
            self.time = time
            self.note = note
            self.weekdays = weekdays
            self.order = order
            self.timestamp = timestamp
            self.active = active
            self.hType = hType
            self.targetCount = targetCount
        }
        
        // Encoding method for Codable conformance
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(color, forKey: .color)
            try container.encode(category, forKey: .category)
            try container.encode(time, forKey: .time)
            try container.encode(note, forKey: .note)
            try container.encode(weekdays, forKey: .weekdays)
            try container.encode(order, forKey: .order)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encode(active, forKey: .active)
            try container.encode(hType, forKey: .healthType)
            try container.encode(targetCount, forKey: .targetCount)
        }
        
        // Decoding method for Codable conformance
        convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(String.self, forKey: .id)
            let title = try container.decode(String.self, forKey: .title)
            let color = try container.decode(String.self, forKey: .color)
            let category = try container.decode(HabitCategory.self, forKey: .category)
            let time = try container.decodeIfPresent(Date.self, forKey: .time)
            let note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
            let weekdays = try container.decode(Set<Weekday>.self, forKey: .weekdays)
            let order = try container.decode(Int.self, forKey: .order)
            let timestamp = try container.decode(Date.self, forKey: .timestamp)
            let active = try container.decode(Bool.self, forKey: .active)
            let hType = try container.decode(String.self, forKey: .healthType)
            let targetCount = try container.decode(Int.self, forKey: .targetCount)
            
            self.init(id: id,
                      title: title,
                      color: color,
                      category: category,
                      time: time,
                      note: note,
                      weekdays: weekdays,
                      order: order,
                      timestamp: timestamp,
                      active: active,
                      hType: hType,
                      targetCount: targetCount)
        }
    }
    
    
    @Model
    final class HabitCategory : Codable, Equatable, Hashable {
        var id: String = UUID().uuidString
        var title:String = ""
        var color: String = "#CCCCCC"
        
        @Relationship
        var habits: [HabitItem]? = []
        
        // Custom CodingKeys to handle encoding/decoding if needed
        private enum CodingKeys: String, CodingKey {
            case id, title, color
        }
        
        init(id: String = UUID().uuidString,
             title: String,
             color: String = "#CCCCCC" ) {
            self.id = id
            self.title = title
            self.color = color
        }
        
        // Encoding method for Codable conformance
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(color, forKey: .color)
        }
        
        // Decoding method for Codable conformance
        convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(String.self, forKey: .id)
            let title = try container.decode(String.self, forKey: .title)
            let color = try container.decode(String.self, forKey: .color)
            
            self.init(id: id,
                      title: title,
                      color: color)
        }
    }
    
    @Model
    class DailyEntry : ObservableObject {
        @Relationship
        var habit: HabitItem?
        
        var date: Date = Date() // date of entry
        var completionDates: [Date] = [] // Store all completion timestamps
        var achievement: Achievement? = Achievement.none // Store earned achievement
        
        // to enable cloud kit and don't break things 
        var habitt:HabitItem {
            get {
                return self.habit!
            }
        }
        
        var isCompleted: Bool {
            get { completionDates.count >= habitt.targetCount }
        }
        
        var completionDate: Date? {
            get { completionDates.last }
        }
                
        init(habit: HabitItem, date: Date, isCompleted: Bool = false, completionDate: Date? = nil) {
            self.habit = habit
            self.date = date
            self.achievement = Achievement.none
            if (isCompleted) {
                self.setCompleted(isCompleted)
            }
        }
    }
}

extension SchemaV4.DailyEntry {
    var isEditingAllowed: Bool {
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
#if DEBUG
        return daysBetween <= 100
#else
        return daysBetween <= 3
#endif
    }
}

extension SchemaV4.HabitItem {
    var healthType: HealthType? {
        get {
            if let healthTypeId = self.hType {
                return HealthType.fromID(healthTypeId)
            }
            return nil
        }
        set {
            hType = newValue?.id
        }
    }
}
