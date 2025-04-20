//
//  HealthActivityTemplate.swift
//  HabitTracker
//

import SwiftUI

struct HealthActivityTemplate: Identifiable, Hashable {
    let healthType: HealthType
    let icon: String
    let defaultColor: String
    
    // Use the health type's ID as the identifier
    var id: String {
        return healthType.id
    }
    
    // For localization
    var localizedName: String {
        if (id == "none") {
            NSLocalizedString("custom_habit", comment: "Health activity name")
        } else {
            NSLocalizedString(id, comment: "Health activity name")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HealthActivityTemplate, rhs: HealthActivityTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}
