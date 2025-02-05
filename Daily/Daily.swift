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
            await Health.shared.updateHabits(entries: entries, for: .now)
            print(entries.count)
            let timelineEntry = HabitWidgetEntry(date: Date(), dailyEntries: entries, showCompleted: configuration.state.rawValue == 1)
            let timeline = Timeline(entries: [timelineEntry], policy: .atEnd)
            completion(timeline)
        }
    }
}


struct DailyEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        let filtered = (entry.showCompleted) ?  entry.dailyEntries : entry.dailyEntries.filter { !$0.isCompleted }
        
        if filtered.isEmpty {
            Text(entry.showCompleted ? "No remaining habits!" : "All habits completed!")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        } else {
            if widgetFamily == .systemSmall {
                WidgetHabitsList(entries: filtered, showCount: 5 )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading )
                    .padding(0)
            } else {
                let perColumn = (widgetFamily == .systemExtraLarge || widgetFamily == .systemLarge) ? 15 : 5

                HStack {
                    let count = filtered.count
                    let firstCount = (count > perColumn) ? perColumn-1 : count-1
                    WidgetHabitsList(entries: Array(filtered[0...firstCount]), showCount: perColumn )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading )
                        .padding(0)
                    if (count > perColumn) {
                        WidgetHabitsList(entries: Array(filtered[perColumn...count-1]), showCount: perColumn)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading )
                            .padding(0)
                    }
                }
            }
                
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


#Preview(as: .systemLarge) {
    Daily()
} timeline: {
    HabitWidgetEntry(date: .now, dailyEntries: sampleDailyEntries(), showCompleted: true)
    HabitWidgetEntry(date: .now, dailyEntries: sampleDailyEntries(), showCompleted: false)
}
