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

struct CirclyStyle: ToggleStyle {
    
    let checkColor:Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            // Checkbox icon
            Image(systemName: "circle.fill")
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
        
        HStack {
            if let entry = entry {
                    Toggle(item.title, isOn: Binding(
                        get: { entry.isCompleted },
                        set: { entry.setCompleted($0) }
                    ))
                    .toggleStyle(CheckboxStyle(checkColor: item.getColor()))
                    .padding(0)
                } else {
                    Toggle(item.title, isOn: .constant(true))
                        .toggleStyle(CirclyStyle(checkColor: item.getColor()))
                        .padding(0)
                }
            
            Spacer()
            
            if let type = item.healthType {
                if type != .none {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            
            Text(item.formattedTime)
        }
    }
}


#Preview {
    let item = HabitItem.init(title: "Task 1", color: Color.red.toHex(), category: HabitCategory(id: "default", title: "Other"), timestamp: .now)
    let entry = DailyEntry.init(habit: item, date: Date(), isCompleted: false)
    HabitItemCell(item: item, entry: entry)
    
    HabitItemCell(item: item, entry: nil)
}
