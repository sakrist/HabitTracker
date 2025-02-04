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
    
    @State private var enableAutocomplete: Bool =  false
    @State private var canEnableAutocomplete: Bool = false
    
    @State private var predefined:String = Health.customHabitName
    
    private var habitItem: HabitItem?
    let supportedHabits = Health.shared.supportedHabits.keys.sorted {
        $0 == Health.customHabitName ? true : ($1 == Health.customHabitName ? false : $0 < $1)
    }

    init(habitItem: HabitItem? = nil) {
        _title = State(initialValue: habitItem?.title ?? "")
        _selectedColor = State(initialValue: habitItem?.getColor() ?? .blue)
        _note = State(initialValue: habitItem?.note ?? "")
        _enableAutocomplete = State(initialValue:(habitItem?.healthType != .none))
        _canEnableAutocomplete = State(initialValue:Health.shared.isSupported(_title.wrappedValue))
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
    
    func openSettings() {
//        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
//            return
//        }
        guard let settingsUrl = URL(string: "x-apple-health://") else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { success in
                if success {
                    print("Settings opened successfully.")
                }
            }
        }
    }
    
    func showReauthorizationAlert() {
        let alert = UIAlertController(
            title: "HealthKit Access Needed",
            message: "To track your health data, please enable HealthKit access in the Settings app.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            self.openSettings()
        })

        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    func healthAutocomplete() {
        let status = Health.shared.isHabitAuthroised(title: title)
        if (status == .notDetermined) {
            Task {
                Health.shared.requestHabitAuthroisation(title: title) { value in
                    enableAutocomplete = value
                }
            }
        }
        
        // apple not indicating if read data is available
        // https://developer.apple.com/documentation/healthkit/hkhealthstore/1614154-authorizationstatus#discussion
//        else if (status == .sharingDenied) {
//            enableAutocomplete = false
//            showReauthorizationAlert()
//        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    HStack {
                        TextField("Enter a habit name...", text: $title)
                            .disabled(canEnableAutocomplete)
                            .foregroundColor(.primary.opacity(canEnableAutocomplete ? 0.5 : 1.0))
                            .onChange(of: title) { oldValue, newValue in
                                if supportedHabits.contains(title) && title != Health.customHabitName {
                                    predefined = title
                                }
                            }

                        ZStack {
                            
                            Picker(selection: $predefined) {
                                ForEach(supportedHabits, id: \.self) { habitName in
                                    Text(habitName).tag(habitName as String?)
                                }
                            } label: {
//                                Image(systemName: (canEnableAutocomplete) ? "heart.fill" : "heart")
//                                    .foregroundStyle(.red)
                            } currentValueLabel: {
                                Image(systemName: (canEnableAutocomplete) ? "heart.fill" : "heart")
                                    .foregroundStyle(.red)
                            }.pickerStyle(.menu)
                                .onChange(of: predefined) { _, _ in
                                    // Trigger animation when the title changes
                                    if let habitType = Health.shared.supportedHabits[predefined] {
                                        withAnimation {
                                            canEnableAutocomplete = (habitType != .none)
                                        }
                                        title = (habitType != .none) ? predefined : ""
                                        enableAutocomplete = false
                                    }
                                }
                        }
                    }
                }
                
                if canEnableAutocomplete {
                    Section(header: Text("Health and Fitness")) {
                        Toggle("Smart Autocomplete", isOn: $enableAutocomplete)
                            .onChange(of: enableAutocomplete) { oldValue, newValue in
                                if (newValue) {
                                    healthAutocomplete()
                                }
                            }
                    }.transition(.opacity)
                }
                
                
                Section(header: Text("Active Days")) {
                    WeekdaysView(activeWeekdays:$activeWeekdays)
                }
                
                Section(header: Text("Time Sensitive")) {
                    Toggle("Reminder", isOn: $timeSensetive)
                    
                    if timeSensetive {
                        DatePicker("Select Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                }.onChange(of: timeSensetive) { value, newValue in
                    if (!ModelData.shared.notificationsEnabled) {
                        requestNotificationPermission()
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
                
#if os(iOS)
                let placementleading:ToolbarItemPlacement = .navigationBarLeading
                let placementTailing:ToolbarItemPlacement = .navigationBarTrailing
#elseif os(macOS)
                let placementleading:ToolbarItemPlacement = .automatic
                let placementTailing:ToolbarItemPlacement = .automatic
#endif
                if habitItem == nil {  // Show toolbar only if adding a new habit
                    ToolbarItem(placement: placementleading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: placementTailing) {
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
        categories = ModelData.shared.fetchCategories()
    }
    
    private func recoverOldItem() {
        showingDuplicateAlert = false
        
        if let existingItem {
            existingItem.active = true
            ModelData.shared.saveContext()
        }
        dismiss()
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
        
        if let habitItem = habitItem {
            finalise(habitItem)
        }
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
        
        finalise(newHabit)
    }
    
    
    
    func finalise(_ habit:HabitItem) {
        
        if (canEnableAutocomplete && enableAutocomplete) {
            habit.healthType = Health.shared.supportedHabits[title] ?? HealthType.none
        } else {
            habit.healthType = HealthType.none
        }
        
        if habit.healthType != HealthType.none {
            Health.shared.enableHabitBackgroundDelivery(habit:habit) { value in
                // TODO: show error
                if (!value) {
                    habit.healthType = HealthType.none
                    enableAutocomplete = false
                }
            }
        } else {
            Health.shared.disableHabitBackgroundDelivery(habit:habit)
        }
        
        
        // setup Notificaitons
        reScheduleWeekdayNotification(habitItem: habit)
        
        // save
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


