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
    let item: HabitItem
    var entry: DailyEntry?
    @State private var showingAlertCannotEdit = false
    
    var body: some View {
        HStack {
            if let entry = entry {
                if item.targetCount > 1 {
                    HStack {
                        ZStack {
                            if entry.completionDates.count >= item.targetCount {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(item.getColor())
                                    .font(.system(size: 24))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(item.getColor())
                                    .font(.system(size: 24))
                                
                                Text("\(entry.completionDates.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(item.getColor())
                            }
                        }
                        
                        Text(item.title)
                            .foregroundColor(.primary)
                    }
                    .contentShape(Rectangle())  // Make entire row tappable
                    .onTapGesture {
                        if entry.isEditingAllowed {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if entry.completionDates.count < item.targetCount {
                                    entry.setCompleted(true)
                                } else {
                                    entry.setCompleted(false)
                                }
                            }
                        } else {
                            showingAlertCannotEdit = true
                        }
                    }
                } else {
                    Toggle(item.title, isOn: Binding(
                        get: { entry.isCompleted },
                        set: { newValue in
                            if entry.isEditingAllowed {
                                entry.setCompleted(newValue)
                            } else {
                                showingAlertCannotEdit = true
                            }
                        }
                    ))
                    .toggleStyle(CheckboxStyle(checkColor: item.getColor()))
                }
                
            } else {
                Toggle(item.title, isOn: .constant(true))
                    .toggleStyle(CirclyStyle(checkColor: item.getColor()))
                    .padding(0)
            }
            
            Spacer()
            
            if let entry = entry, item.targetCount > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<item.targetCount, id: \.self) { index in
                        Circle()
                            .fill(index < entry.completionDates.count ? item.getColor() : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if let type = item.healthType {
                if type != .none {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            
            Text(item.formattedTime)
        }
        .alert("Cannot Edit Past Records", isPresented: $showingAlertCannotEdit) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("For accuracy, habits can only be edited within 3 days of their completion date.")
        }
    }
}


#Preview {
    let item = HabitItem.init(title: "Task 1", color: Color.red.toHex(), category: HabitCategory(id: "default", title: "Other"), timestamp: .now)
    let entry = DailyEntry.init(habit: item, date: Date(), isCompleted: false)
    HabitItemCell(item: item, entry: entry)
    
    HabitItemCell(item: item, entry: nil)
}
