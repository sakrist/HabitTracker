//
//  HabitItem.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import Foundation
import SwiftData
import SwiftUI



@Model
final class HabitItem : Codable {
    var id: String
    var title: String
    var color: String = "#FF0000"
    var time: Date?
    var note: String?
    var weekdays: Set<HabitItem.Weekday>
    
    var order: Int = 0
    var timestamp: Date // created date
    var active: Bool = true
    
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
    }
    
    // Custom CodingKeys to handle encoding/decoding if needed
    private enum CodingKeys: String, CodingKey {
        case id, title, color, time, note, weekdays, order, timestamp, active
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         color: String = "#FF0000",
         time: Date? = nil,
         note: String? = nil,
         weekdays: Set<Weekday> = [],
         order: Int = 0,
         timestamp: Date = Date(),
         active: Bool = true) {
        self.id = id
        self.title = title
        self.color = color
        self.time = time
        self.note = note
        self.weekdays = weekdays
        self.order = order
        self.timestamp = timestamp
        self.active = active
    }
    
    // Encoding method for Codable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(color, forKey: .color)
        try container.encode(time, forKey: .time)
        try container.encode(note, forKey: .note)
        try container.encode(weekdays, forKey: .weekdays)
        try container.encode(order, forKey: .order)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(active, forKey: .active)
    }

    // Decoding method for Codable conformance
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let color = try container.decode(String.self, forKey: .color)
        let time = try container.decodeIfPresent(Date.self, forKey: .time)
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        let weekdays = try container.decode(Set<Weekday>.self, forKey: .weekdays)
        let order = try container.decode(Int.self, forKey: .order)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let active = try container.decode(Bool.self, forKey: .active)

        self.init(id: id,
                  title: title,
                  color: color,
                  time: time,
                  note: note,
                  weekdays: weekdays,
                  order: order,
                  timestamp: timestamp,
                  active: active)
    }
    
    func deactivate() {
        active.toggle()
    }
    
    var isActive: Bool {
        return active
    }
    
    var isTimeSensitive: Bool {
        return time != nil
    }
    
    func getColor() -> Color {
        return Color(hex: color) ?? .secondary
    }
    
    // Computed property to format the time as a string
    var formattedTime: String {
        if let time = time {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("j:mm")
            return formatter.string(from: time)
        }
        return ""
    }
    
    static private func dateAt(for date: Date, hour: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
    
//    static let sampleData:[HabitItem] = [
//        .init(id:"1", title: "Run", color: Color.red.toHex(), weekdays: .init(Weekday.allCases)),
//        .init(id:"2", title: "Workout", color: Color.blue.toHex(), weekdays: .init(Weekday.allCases)),
//        .init(id:"3", title: "Meditate", color: Color.blue.toHex(), weekdays: .init(Weekday.allCases)),
//        .init(id:"4", title: "Write", color: Color.green.toHex(), weekdays: .init(Weekday.allCases))
//    ]
    
    static let sampleData: [HabitItem] = [
        HabitItem(
            title: "Morning Meditation",
            color: "#3498DB",
            time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
            note: "15 minutes of meditation",
            weekdays: [.monday, .wednesday, .friday],
            order: 1
        ),
        HabitItem(
            title: "Exercise",
            color: "#E74C3C",
            time: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()),
            note: "30 minutes of running",
            weekdays: [.tuesday, .thursday, .saturday],
            order: 2
        ),
        HabitItem(
            title: "Read a Book",
            color: "#9B59B6",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
            note: "Read for 30 minutes",
            weekdays: [.monday, .wednesday, .friday, .sunday],
            order: 3
        ),
        HabitItem(
            title: "Drink Water",
            color: "#1ABC9C",
            time: nil,
            note: "8 glasses of water",
            weekdays: .init(Weekday.allCases),
            order: 4
        ),
        HabitItem(
            title: "Plan Tomorrow",
            color: "#F1C40F",
            time: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
            note: "10 minutes to plan the next day",
            weekdays: .init(Weekday.allCases),
            order: 5
        ),
        HabitItem(
            title: "Stretch",
            color: "#2ECC71",
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()),
            note: "5 minutes of stretching",
            weekdays: [.tuesday, .thursday, .saturday],
            order: 6
        ),
        HabitItem(
            title: "Write Journal",
            color: "#E67E22",
            time: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()),
            note: "Reflect on the day",
            weekdays: [.sunday],
            order: 7
        )
    ]
}
