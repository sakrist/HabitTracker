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
    var habitItem: HabitItem?

    init(habitItem: HabitItem? = nil) {
        _title = State(initialValue: habitItem?.title ?? "")
        _selectedColor = State(initialValue: habitItem?.getColor() ?? .blue)
        _note = State(initialValue: habitItem?.note ?? "")
        self.habitItem = habitItem
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Title", text: $title)
                    
                    ColorPicker("Select Color", selection: $selectedColor)
                    
                }
            }
            .navigationTitle(habitItem == nil ? "New Habit" : "Edit Habit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                        dismiss()
                    }
                    .disabled(title.isEmpty)  // Disable save if the title is empty
                }
            }
        }
    }
    
    private func saveHabit() {
        if let habitItem = habitItem {
            // Editing an existing habit
            habitItem.title = title
            habitItem.color = selectedColor.toHex() ?? "#00FF00"
        } else {
            // Creating a new habit
            let newHabit = HabitItem(title: title, color: selectedColor, timestamp: Date())
            modelContext.insert(newHabit)
        }
    }
}


#Preview("New Habit") {
    AddHabitView()
}

#Preview("Edit Habit") {
    AddHabitView(habitItem: HabitItem(
        title: "Morning Run",
        color: .green,
        timestamp: Date()
    ))
}
