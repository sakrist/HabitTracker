//
//  ActivityTypePickerView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 21/04/2025.
//

import SwiftUI

struct ActivityTypePickerView: View {
    @Binding var selectedHealthType: HealthType
    @Binding var title: String
    @Binding var selectedColor: Color
    let habitItem: HabitItem?
    let predefined: String
    let onSelectActivity: (Bool) -> Void
    
    var body: some View {
        Picker(selection: $selectedHealthType) {
            ForEach(Health.shared.activityTemplates, id: \.id) { template in
                HStack {
                    Image(systemName: template.icon)
                        .foregroundColor(Color(hex: template.defaultColor))
                        .frame(width: 24)
                    Text(template.localizedName)
                }
                .tag(template.healthType)
            }
        } label: {
            
        } currentValueLabel: {
            if let template = Health.shared.findTemplate(byHealthType: selectedHealthType) {
                Image(systemName:  template.icon)
                    .foregroundStyle(.red)
            }
        }.pickerStyle(.menu)
        .onChange(of: selectedHealthType) { _, newValue in
            // If user hasn't edited the title yet, suggest the template name
            if title.isEmpty || title == predefined,
               let template = Health.shared.findTemplate(byHealthType: newValue) {
                title = template.localizedName
                // Set the color if it's a new habit
                if habitItem == nil {
                    selectedColor = Color(hex: template.defaultColor) ?? .random()
                }
            }
            if let template = Health.shared.findTemplate(byHealthType: newValue) {
                _ = print("template.healthType.id \(template.healthType.id)")
            }
            // Update autocomplete status
            onSelectActivity(newValue != .none)
        }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var selectedHealthType: HealthType = .none
        @State private var title = ""
        @State private var selectedColor = Color.blue
        
        var body: some View {
            Form {
                Section(header: Text("Activity Type")) {
                    ActivityTypePickerView(
                        selectedHealthType: $selectedHealthType,
                        title: $title,
                        selectedColor: $selectedColor,
                        habitItem: nil,
                        predefined: Health.customHabitName,
                        onSelectActivity: { _ in }
                    )
                }
                
                Section(header: Text("Selected Values")) {
                    Text("Type: \(selectedHealthType.id)")
                    Text("Title: \(title)")
                    
                    HStack {
                        Text("Color:")
                        Rectangle()
                            .fill(selectedColor)
                            .frame(width: 30, height: 30)
                            .cornerRadius(6)
                    }
                }
            }
            .padding()
        }
    }
    
    return PreviewContainer()
}
