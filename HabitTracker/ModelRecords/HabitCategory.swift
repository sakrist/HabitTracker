//
//  HabitCategory.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/01/2025.
//

import Foundation
import SwiftData
import SwiftUI



@Model
final class HabitCategory : Codable, Equatable, Hashable {
    var id: String
    var title:String
    var color: String
    
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
    
    // equal compare function
    static func == (lhs: HabitCategory, rhs: HabitCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(color)
    }

}
