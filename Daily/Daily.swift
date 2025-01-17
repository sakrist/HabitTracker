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
    let showCompleted: Bool
}


struct Provider: @preconcurrency IntentTimelineProvider {
    typealias Entry = HabitWidgetEntry
    
    typealias Intent = HabitWidgetConfigurationIntent
    
    
    let modelData:ModelData
    
    @MainActor
    func fetchEntries() -> [DailyEntry] {
        return fetchHabitEntries(modelContext: modelData.modelContainer.mainContext, for: Date())
    }
    
    @MainActor func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: Date(), dailyEntries: sampleDailyEntries(), showCompleted: true)
    }

    @MainActor
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let sampleEntries = sampleDailyEntries()
        completion(HabitWidgetEntry(date: Date(), dailyEntries: sampleEntries, showCompleted: configuration.state.rawValue == 1))
    }

    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
    
        Task {
            let entries = await fetchEntries()
            print(entries.count)
            let timelineEntry = HabitWidgetEntry(date: Date(), dailyEntries: entries, showCompleted: configuration.state.rawValue == 1)
            let timeline = Timeline(entries: [timelineEntry], policy: .atEnd)
            completion(timeline)
        }
    }
}


struct DailyEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        let filtered = (entry.showCompleted) ?  entry.dailyEntries : entry.dailyEntries.filter { !$0.isCompleted }
        
        if filtered.isEmpty {
            Text(entry.showCompleted ? "No remaining habits!" : "All habits completed!")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        } else {
            WidgetHabitsList(entries: filtered)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading )
                .padding(0)
        }
    }
}

struct Daily: Widget {
    let kind: String = "Daily"

    let modelData = ModelData.shared
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: HabitWidgetConfigurationIntent.self, provider: Provider(modelData:modelData)) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                DailyEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DailyEntryView(entry: entry)
                    .padding()
                    .background()
            }
                
        }
        .configurationDisplayName("Current Day")
        .description("Display habits for the current day")
    }
}

#Preview(as: .systemSmall) {
    Daily()
} timeline: {
    HabitWidgetEntry(date: .now, dailyEntries: sampleDailyEntries(), showCompleted: true)
    HabitWidgetEntry(date: .now, dailyEntries: sampleDailyEntries(), showCompleted: false)
    HabitWidgetEntry(date: .now, dailyEntries: [], showCompleted: false)
    HabitWidgetEntry(date: .now, dailyEntries: [], showCompleted: true)
}


