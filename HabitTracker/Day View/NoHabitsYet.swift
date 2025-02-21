//
//  NoHabitsYet.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//

import SwiftUI
import RainbowUI

struct NoHabitsYet: View {
    
    @Binding var selectedTab: Int
    @Binding var showAddHabit: Bool
    
    var body: some View {
        VStack {
            // show button add habits which will navigate to Habits tab
            Spacer()
            Text("Start by adding habits you already do daily.\n")
            
            Text(" · · · ")
            
            Text("If you want to build a new habit, \nstart by adding one habit at a time.\n")
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 150)
            
            Button {
                // navigate to Habits tab
                selectedTab = 1
                showAddHabit = true
            } label: {
                Text("Add Habits")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .font(.title)
            .buttonStyle(RainbowButtonStyle())
            
            Spacer()
        }
    }
}


#Preview {
    NoHabitsYet(selectedTab: .constant(0), showAddHabit: .constant(false))
}
