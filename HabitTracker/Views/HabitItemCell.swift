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
    private let previewCurrentStreak: Int?
    @State private var showingAlertCannotEdit = false
    
    init(item: HabitItem, entry: DailyEntry? = nil, previewCurrentStreak: Int? = nil) {
        self.item = item
        self.entry = entry
        self.previewCurrentStreak = previewCurrentStreak
    }
    
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
            
            if currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                    Text("\(currentStreak)")
                }
                .font(.caption.bold())
                .foregroundColor(item.getColor())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(item.getColor().opacity(0.12))
                )
                .accessibilityLabel("\(currentStreak) day streak")
            }
            
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
    
    private var currentStreak: Int {
        if let previewCurrentStreak {
            return previewCurrentStreak
        }
        
        guard let entry else {
            return 0
        }
        
        let (streak, _, _, _) = ModelData.shared.calculateStreak(habit: item, for: entry.date, end: entry.date.endOfDay)
        return streak
    }
}

private extension Date {
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}


#Preview {
    let item = HabitItem.init(title: "Task 1", color: Color.red.toHex(), category: HabitCategory(id: "default", title: "Other"), timestamp: .now)
    let entry = DailyEntry.init(habit: item, date: Date(), isCompleted: false)
    
    let completedItem = HabitItem.init(title: "Read book", color: Color.green.toHex(), category: HabitCategory(id: "default", title: "Other"), timestamp: .now)
    let completedEntry = DailyEntry.init(habit: completedItem, date: Date(), isCompleted: true)
    
    let item2 = HabitItem.init(title: "Morning run", color: Color.blue.toHex(), category: HabitCategory(id: "default", title: "Other"), timestamp: .now, targetCount: 3)
    let entry2 = DailyEntry.init(habit: item2, date: Date(), isCompleted: false)
    entry2.completionDates = [Date(), Date()]

    return VStack(alignment: .leading, spacing: 16) {
        HabitItemCell(item: item, entry: entry, previewCurrentStreak: 0)
        HabitItemCell(item: completedItem, entry: completedEntry, previewCurrentStreak: 5)
        HabitItemCell(item: item2, entry: entry2, previewCurrentStreak: 12)
        HabitItemCell(item: item, entry: nil)
    }
    .padding()
}
