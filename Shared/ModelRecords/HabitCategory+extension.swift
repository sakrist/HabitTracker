//
//  HabitCategory.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/01/2025.
//

import Foundation
import SwiftData
import SwiftUI

extension HabitCategory {
    
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
