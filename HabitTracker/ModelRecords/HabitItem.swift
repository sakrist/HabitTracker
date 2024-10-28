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
final class HabitItem {
    var title: String
    var color: String = "#FF0000"
    
    var time: Date?
    
    
    // created date
    var timestamp: Date
    var id: String
    
    var note: String?
    
    var active: Bool = true
    var order: Int = 0
    
    
    var isTimeSensitive: Bool {
        return time != nil
    }
    
    enum Weekday: Int, CaseIterable, Identifiable, Codable {
        
        var id: Int { rawValue }
        
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        case sunday = 1
        
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
    
    var weekdays: Set<Weekday>
    
    init(id:String? = nil, title:String, color: Color, timestamp: Date? = nil) {
        self.id = id ?? UUID().uuidString
        self.color = color.toHex() ?? "#FF0000"
        self.title = title
        self.timestamp = HabitItem.dateAt(for:.now, hour: 8) ?? .now
        self.weekdays = Set(HabitItem.Weekday.allCases)
    }
    
    func deactivate() {
        active.toggle()
    }
    
    var isActive: Bool {
        return active
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
    
    static let sampleData:[HabitItem] = [
        .init(id:"1", title: "Run", color: .red),
        .init(id:"2", title: "Workout", color: .blue),
        .init(id:"3", title: "Meditate", color: .blue),
        .init(id:"4", title: "Write", color: .green)
    ]
}
