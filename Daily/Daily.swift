//
//  Daily.swift
//  Daily
//
//  Created by Volodymyr Boichentsov on 14/01/2025.
//

import WidgetKit
import SwiftUI


struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let dailyEntries: [DailyEntry]
}


struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: Date(), dailyEntries: sampleDailyEntries())
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let sampleEntries = sampleDailyEntries()
        completion(HabitWidgetEntry(date: Date(), dailyEntries: sampleEntries))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        @MainActor
        func fetchEntries() -> [DailyEntry] {
            let modelData = ModelData.shared
            return fetchHabitEntries(modelContext: modelData.modelContainer.mainContext, for: Date())
        }

        Task {
            let entries = await fetchEntries()
            let timelineEntry = HabitWidgetEntry(date: Date(), dailyEntries: entries)
            let timeline = Timeline(entries: [timelineEntry], policy: .atEnd)
            completion(timeline)
        }
    }
}


struct DailyEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        HabitsList(entries: entry.dailyEntries)
    }
}

struct Daily: Widget {
    let kind: String = "Daily"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                DailyEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DailyEntryView(entry: entry)
                    .padding()
                    .background()
            }
                
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    Daily()
} timeline: {
    HabitWidgetEntry(date: .now, dailyEntries: sampleDailyEntries())
}


func sampleDailyEntries() -> [DailyEntry] {
    [
        DailyEntry(habit: HabitItem.sampleData[0], date: Date(), isCompleted: false),
        DailyEntry(habit: HabitItem.sampleData[1], date: Date(), isCompleted: true),
        DailyEntry(habit: HabitItem.sampleData[2], date: Date(), isCompleted: false)
    ]
}
