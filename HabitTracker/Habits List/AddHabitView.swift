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

    @State private var selectedCategory: HabitCategory?
    @State private var categories: [HabitCategory] = []
    private var habitItem: HabitItem?

    init(habitItem: HabitItem? = nil) {
        _title = State(initialValue: habitItem?.title ?? "")
        _selectedColor = State(initialValue: habitItem?.getColor() ?? .blue)
        _note = State(initialValue: habitItem?.note ?? "")
        
        _selectedCategory = State(initialValue: habitItem?.category ?? ModelData.shared.defaultCategory())

        self.habitItem = habitItem
        if let habitItem = habitItem {
            activeWeekdays = habitItem.weekdays
            timeSensetive = (habitItem.time != nil)
            time = habitItem.time ?? Date.now
            selectedCategory = habitItem.category
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

                    WeekdaysView(activeWeekdays:$activeWeekdays)
                }
                
                Section(header: Text("Time")) {
                    Toggle("Time sensetime", isOn: $timeSensetive)
                    
                    if timeSensetive {
                        DatePicker("Select Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("Color")) {
                    ColorPicker("Select Color", selection: $selectedColor)
                }
                
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.id) { category in
                            Text(category.title)
                                .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onAppear {
                        loadCategories()
                    }
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
    
    private func loadCategories() {
        categories = ModelData.shared.defaultCategories()
    }
    
    private func saveHabit() {
        
        if let habitItem = habitItem {
            // Editing an existing habit
            habitItem.title = title
            habitItem.color = selectedColor.toHex()
            habitItem.weekdays = activeWeekdays
            habitItem.time = (timeSensetive) ? time : nil
            habitItem.category = selectedCategory
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
        
        ModelData.shared.saveContext()
        dismiss()
    }
    
    private func recoverOldItem() {
        showingDuplicateAlert = false
        
        if let existingItem {
            existingItem.active = true
            ModelData.shared.saveContext()
        }
        dismiss()
    }
    
    private func createNewHabit() {
        showingDuplicateAlert = false
        
        let habits = fetchHabits(modelContext: modelContext)
        
        // Creating a new habit
        let newHabit = HabitItem(title: title, color: selectedColor.toHex(), category: selectedCategory, timestamp: Date())
        newHabit.weekdays = activeWeekdays
        if (timeSensetive) {
            newHabit.time = time
        }
        newHabit.order = habits.count
        modelContext.insert(newHabit)
        
        ModelData.shared.saveContext()
        dismiss()
    }
    
}


//#Preview("New Habit") {
//    AddHabitView()
//}

#Preview("Edit Habit") {
    AddHabitView(habitItem: HabitItem(
        title: "Morning Run",
        color: Color.green.toHex(),
        category: HabitCategory(id: "default", title: "Other"),
        timestamp: Date()
    )).modelContainer(SampleData.shared.modelContainer)
}


