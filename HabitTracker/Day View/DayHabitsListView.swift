//
//  HabitsList.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//
import SwiftUI
import SwiftData
import AVFoundation
#if !os(watchOS)
import RainbowUI
import ConfettiSwiftUI
#endif

func motivationMessage() -> String {
    
    let motivationalQuotes: Set<String> = [
    "All done for today!",
    "You crushed it! ⭐️",
    "Daily streak complete!",
    "Nothing left — you nailed it!",
    "You're on fire! 🔥",
    "Discipline looks good on you.",
    "Habits done. Progress locked in.",
    "Small wins, big future.",
    "Consistency is your superpower." ]
    return motivationalQuotes.randomElement() ?? motivationalQuotes.first!
}


struct DayHabitsListView: View {
    var date:Date
    @Query private var entries: [DailyEntry]
    
    var filteredEntries: [DailyEntry] {
        let wd = HabitItem.Weekday(date: date)
        return entries.filter { $0.habit?.weekdays.contains(wd) == true }.sorted(by: sortDailyHabits)
    }
    
    @State var showAddHabit: Bool = false
    
    @State private var counter: Int = 0
    @State private var audioPlayer2: AVAudioPlayer?
    
    @State private var showMessage = false // Controls the visibility of the message
    
    @State private var showAchievement = false
    @State private var currentAchievement: Achievement = .none
    
    init(date: Date) {
        self.date = date

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        _entries = Query(
            filter: #Predicate<DailyEntry> { entry in
                entry.date >= start && entry.date < end &&
                entry.habit?.active == true
            }
        )
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                List {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(destination: HabitDetailProgressView(date: date, habit:entry.habitt)) {
                            HabitItemCell(item: entry.habitt, entry: entry)
                                .contentShape(Rectangle())
                                .onChange(of: entry.completionDates) { oldValue, newValue in
                                    ModelData.shared.saveContext()
                                }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .overlay(alignment: .top) {
                let title = achievementTitle(achievement: currentAchievement)
                let icon = achievementIcon(achievement: currentAchievement)
                // Use the color of the habit that triggered the achievement
                let color = filteredEntries.first(where: { $0.achievement == currentAchievement })?.habitt.getColor() ?? .blue
                AchievementBanner(title: title, icon: icon, color: color, isPresented: $showAchievement)
            }
            .listStyle(.plain)
#if !os(watchOS)
            .confettiCannon(trigger: $counter, num: 100, rainHeight: 250)
#endif
            VStack {
                // Overlay message
                if showMessage {
                    Text(motivationMessage())
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .fontWeight(.bold)
#if !os(watchOS)
                        .rainbowRun()
#endif
                        .opacity(showMessage ? 1 : 0) // Fade in and out
                }
            }
        }
    }
    
    private func completeHabits() {
        withAnimation {
            showMessage = true // Show the message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showMessage = false // Hide the message after 1 second
            }
        }
    }

    private func changed(entry:DailyEntry, _ old:Bool, _ new:Bool) {
        
        if (date.isToday()) {
            
            let achievement = ModelData.shared.completedEntry(entry: entry)

            if achievement != .none {
                currentAchievement = achievement
                showAchievement = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showAchievement = false
                }
                // play achivement sound
                playSound(name: "achive-sound-5.caf")
            }
            entry.achievement = achievement
            
#if !os(watchOS)
            if (new) {
                silenceTodaysNotification(identifier: entry.habitt.id)
            } else {
                reScheduleWeekdayNotification(habitItem: entry.habitt)
            }
#endif
            let countCompleted = filteredEntries.reduce(0) { $0 + ($1.isCompleted ? 1 : 0)}
            
            if (countCompleted == filteredEntries.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    counter += 1
                    playSound(name: "Balloon Pop.caf")
                    completeHabits()
                }
            }
        }
        ModelData.shared.saveContext()
    }

    
    // Set up the audio player
    private func playSound(name: String) {
        guard let soundURL = Bundle.main.url(forResource:name, withExtension: nil) else {
            print("Audio file not found.")
            return
        }

        do {
#if os(iOS)
            try AVAudioSession.sharedInstance()
                .setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance()
                .setActive(true)
#endif
            audioPlayer2 = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer2?.prepareToPlay()
        } catch {
            print("Error initializing audio player: \(error)")
        }
        audioPlayer2?.play()
    }
}

#Preview {
    let entries = fetchHabitEntries(modelContext: ModelData.shared.modelContainer.mainContext, for: Date())
    DayHabitsListView(date: Date())
}
