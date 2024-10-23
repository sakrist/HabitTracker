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
    
    init(id:String? = nil, title:String, color: Color, timestamp: Date? = nil) {
        self.id = id ?? UUID().uuidString
        self.color = color.toHex() ?? "#FF0000"
        self.title = title
        self.timestamp = HabitItem.dateAt(for:.now, hour: 8) ?? .now
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
        .init(id:"3", title: "Write", color: .green)
    ]
}
