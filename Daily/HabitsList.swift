//
//  HabitItemCell.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 16/01/2025.
//

import SwiftUI

struct SimpleHabitItemCell: View {
    let item: HabitItem
    var entry: DailyEntry?

    var body: some View {
        HStack {
            // Static checkbox representation
            Image(systemName: (entry?.isCompleted ?? false) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.getColor())
                .font(.system(size: 24))

            // Habit title
            Text(item.title)
                .foregroundColor(.primary)
                .lineLimit(1)
        }.padding(0)
    }
}

struct WidgetHabitsList: View {
    let entries: [DailyEntry]

    let showCount = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(entries.prefix(showCount)) { entry in // Limit to 5 for small widget size
                SimpleHabitItemCell(item: entry.habit, entry: entry)
            }.padding(0)
            
            if entries.count > 4 {
                HStack {
                    Spacer()
                    Text("…and more")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, -10)
                    
                }.padding(0)
            }
        }
        .padding(0)
        
    }
}


// preview
#Preview {
    WidgetHabitsList(entries: sampleDailyEntries())
        .border(.blue, width: 1).frame(width: 150, height: 150, alignment: .center)
}
