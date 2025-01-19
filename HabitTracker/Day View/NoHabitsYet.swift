//
//  NoHabitsYet.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//

import SwiftUI
import RainbowButton

struct NoHabitsYet: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            // show button add habits which will navigate to Habits tab
            Spacer()
            Text("Start by adding habits you already do daily.\n")
            
            Text(" · · · ")
            
            Text("If you want to build a new habits, \nstart by adding one habit at a time.\n")
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 150)
            
            Button(action: {
                // navigate to Habits tab
                selectedTab = 1
            }) {
                Text("Add Habits")
            }.font(.largeTitle)
                .buttonStyle(RainbowButtonStyle())
            Spacer()
        }
    }
}


#Preview {
    NoHabitsYet(selectedTab: .constant(0))
}
