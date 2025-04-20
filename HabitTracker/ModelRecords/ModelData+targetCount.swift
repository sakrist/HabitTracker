import SwiftData
import Foundation

extension ModelData {
    func updateHabitTargetCount(_ habit: HabitItem, newCount: Int) {
        let oldCount = habit.targetCount
        guard oldCount != newCount else { return }
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                if let h = entry.habit  {
                    h.id == habit.id
                } else {
                    false
                }
                
            }
        )
        
        do {
            let allEntries = try modelContainer.mainContext.fetch(descriptor)
            let completedEntries = allEntries.filter { $0.completionDates.count == oldCount }
            
            for entry in completedEntries {
                if newCount > oldCount {
                    // Increasing target count: duplicate last completion date
                    while entry.completionDates.count < newCount {
                        if let lastDate = entry.completionDates.last {
                            entry.completionDates.append(lastDate)
                        }
                    }
                } else {
                    // Reducing target count: keep only first N dates
                    if entry.completionDates.count > newCount {
                        entry.completionDates = Array(entry.completionDates.prefix(newCount))
                    }
                }
            }
            
            habit.targetCount = newCount
            saveContext()
            
        } catch {
            print("Error updating target count: \(error)")
        }
    }
}
