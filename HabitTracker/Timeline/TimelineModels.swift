import SwiftUI
import SwiftData

// Model to hold completion entry info
struct CompletionEntry: Identifiable {
    let id = UUID()
    let entry: DailyEntry
    let completionDate: Date
    let index: Int
    
    init(entry: DailyEntry, completionDate: Date) {
        self.entry = entry
        self.completionDate = completionDate
        if let index = entry.completionDates.firstIndex(of: completionDate) {
            self.index = index
        } else {
            self.index = 0
        }
    }
}

struct TimelineGroup: Identifiable {
    let id = UUID()
    let date: Date
    let completionEntries: [CompletionEntry]
}
