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
            if item.targetCount > 1 {
                // Custom indicator for multiple targets
                ZStack {
                    Circle()
                        .stroke(item.getColor(), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    if let entry = entry {
                        Text("\(entry.completionDates.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(item.getColor())
                    }
                }
            } else {
                // Standard checkbox for single target
                Image(systemName: (entry?.isCompleted ?? false) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.getColor())
            }

            // Habit title
            Text(item.title)
                .foregroundColor(.primary)
                .font(.system(size: 14))
                .lineLimit(1)
        }.padding(0)
    }
}

struct WidgetHabitsList: View {
    let entries: [DailyEntry]

    let showCount:Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(entries.prefix(showCount)) { entry in // Limit to 5 for small widget size
                SimpleHabitItemCell(item: entry.habit, entry: entry)
            }.padding(0)
            
            if entries.count > showCount {
                HStack {
                    Spacer()
                    Text("…and more")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, -4)
                    
                }.padding(0)
            }
        }
        .padding(0)
        
    }
}


// preview
#Preview {
    WidgetHabitsList(entries: sampleDailyEntries(), showCount:5)
        .border(.blue, width: 1).frame(width: 150, height: 150, alignment: .center)
}
