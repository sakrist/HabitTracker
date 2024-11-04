//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 13/10/2024.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedColor: Color
    @State private var note: String
    
    @State private var time: Date
    @State private var timeSensetive: Bool
    
    @State private var showingDuplicateAlert = false
    @State private var existingItem: HabitItem? = nil
    
    @State private var activeWeekdays: Set<HabitItem.Weekday>

    private var habitItem: HabitItem?

    init(habitItem: HabitItem? = nil) {
        _title = State(initialValue: habitItem?.title ?? "")
        _selectedColor = State(initialValue: habitItem?.getColor() ?? .blue)
        _note = State(initialValue: habitItem?.note ?? "")
        self.habitItem = habitItem
        if let habitItem = habitItem {
            activeWeekdays = habitItem.weekdays
            timeSensetive = (habitItem.time != nil)
            time = habitItem.time ?? Date.now
        } else {
            activeWeekdays = Set(HabitItem.Weekday.allCases)
            timeSensetive = false
            time = Date.now
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
                
                
                Section(header: Text("Active Days")) {
                    // Custom multi-segment control for weekdays
                    HStack(spacing: 2) {
                        ForEach(HabitItem.Weekday.allCases) { day in
                            Button(action: {
                                toggleDaySelection(day)
                            }) {
                                Text(day.displayName)
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(activeWeekdays.contains(day) ? Color.blue : Color.clear)
                                    .foregroundColor(activeWeekdays.contains(day) ? .white : .blue)
                            }
                            .buttonStyle(PlainButtonStyle())  // Remove default button style
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                
                Section(header: Text("Time")) {
                    Toggle("Time sensetime", isOn: $timeSensetive).onSubmit {
                        
                    }
                    
                    
                    if timeSensetive {
                        DatePicker("Select Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("Color")) {
                    ColorPicker("Select Color", selection: $selectedColor)
                }
                
            }
            .navigationTitle(habitItem == nil ? "Add New Habit" : "Edit Habit")
            .toolbar {
                if habitItem == nil {  // Show toolbar only if adding a new habit
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(title.isEmpty)  // Disable save if the title is empty
                }
            }
        }.alert("Duplicate Habit", isPresented: $showingDuplicateAlert) {
            Button("Recover Old Item", action: recoverOldItem)
            Button("Create New", action: createNewHabit)
        } message: {
            Text("A habit with the title '\(title)' already exists. Would you like to recover the old item or create a new one?")
        }
    }
    
    private func saveHabit() {
        
        if let habitItem = habitItem {
            // Editing an existing habit
            habitItem.title = title
            habitItem.color = selectedColor.toHex() ?? "#00FF00"
            habitItem.weekdays = activeWeekdays
            habitItem.time = (timeSensetive) ? time : nil
        } else {
            
            let exists = fetchHabits(modelContext: modelContext, predicate: #Predicate<HabitItem> {item in item.title == title && !item.active})
            
            if exists.count > 0 {
                existingItem = exists.first!
                showingDuplicateAlert = true
                return
            } else {
                createNewHabit()
            }
        }
        
        saveContext()
        dismiss()
    }
    
    private func toggleDaySelection(_ day: HabitItem.Weekday) {
        if activeWeekdays.contains(day) {
            activeWeekdays.remove(day)
        } else {
            activeWeekdays.insert(day)
        }
    }
    
    private func recoverOldItem() {
        showingDuplicateAlert = false
        
        if let existingItem {
            existingItem.active = true
            saveContext()
        }
        dismiss()
    }
    
    private func createNewHabit() {
        showingDuplicateAlert = false
        
        let habits = fetchHabits(modelContext: modelContext)
        
        // Creating a new habit
        let newHabit = HabitItem(title: title, color: selectedColor.toHex(), timestamp: Date())
        newHabit.weekdays = activeWeekdays
        if (timeSensetive) {
            newHabit.time = time
        }
        newHabit.order = habits.count
        modelContext.insert(newHabit)
        
        saveContext()
        dismiss()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()  // Explicitly save the changes to the modelContext
        } catch {
            print("Error saving model context: \(error)")
        }
    }
}


//#Preview("New Habit") {
//    AddHabitView()
//}

#Preview("Edit Habit") {
    AddHabitView(habitItem: HabitItem(
        title: "Morning Run",
        color: Color.green.toHex(),
        timestamp: Date()
    ))
}
