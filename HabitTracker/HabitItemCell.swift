//
//  CheckboxStyle.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//


import SwiftUI

struct CheckboxStyle: ToggleStyle {
    
    let checkColor:Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            // Checkbox icon
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(checkColor)
                .font(.system(size: 24))
                

            // Toggle label
            configuration.label
        }.onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                configuration.isOn.toggle()
            }
        }
    }
}

struct HabitItemCell: View {
    let item:HabitItem
    var entry: DailyEntry?
    
    var body: some View {
        Toggle(item.title, isOn: (entry != nil) ? Binding(
            get: { entry!.isCompleted },
            set: { entry!.isCompleted = $0 }
        ) : .constant(false))
            .toggleStyle(CheckboxStyle(checkColor: item.getColor())) // Applying custom checkbox style
            .padding(0)
    }
}


#Preview {
    let item = HabitItem.init(title: "Task 1", color: .red, timestamp: .now)
    HabitItemCell(item: item)
}
