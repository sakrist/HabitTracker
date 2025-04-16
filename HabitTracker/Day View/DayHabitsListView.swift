//
//  HabitsList.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 19/01/2025.
//
import SwiftUI
import SwiftData
import ConfettiSwiftUI
import AVFoundation
import RainbowUI


func title(achievement:Achievement) -> String {
    switch achievement {
    case .completionStreakWeek:
        return "7 Day Streak!"
    case .completionStreak2Weeks:
        return "2 Week Warrior!"
    case .completionMonth:
        return "Monthly Master!"
    case .completionStreak50:
        return "50 Day Champion!"
    case .completionStreak100:
        return "100 Day Legend!"
    case .completionYear:
        return "Year of Excellence!"
    case .completionRenewed:
        return ["Back on track!" , "Keep it up!", "Glad you are back!", "You are back!"].randomElement() ?? "Yaaaay!"
    case .completionRenewed2:
        return "Fresh Start!"
    case .completionRenewed3:
        return "New Beginning!"
    case .completionTotal30:
        return "30 Total Completions!"
    case .completionTotal66:
        return "66 Sticking Point!"
    case .completionTotal100:
        return "Century Club!"
    case .completionTotal365:
        return "365 Days Complete!"
    case .none:
        return ""
    }
}

func icon(achievement:Achievement) -> String {
    switch achievement {
    case .completionStreakWeek:
        return "🔥"
    case .completionStreak2Weeks:
        return "💪"
    case .completionMonth:
        return "🌟"
    case .completionStreak50:
        return "👑"
    case .completionStreak100:
        return "🏆"
    case .completionYear:
        return "🎯"
    case .completionRenewed, .completionRenewed2, .completionRenewed3:
        return "🎉"
    case .completionTotal30:
        return "🌠"
    case .completionTotal66:
        return "🧲"
    case .completionTotal100:
        return "💯"
    case .completionTotal365:
        return "📆"
    case .none:
        return ""
    }
}

func motivationMessage() -> String {
    
    let motivationalQuotes: Set<String> = [
    "All done for today!",
    "You crushed it! ✅",
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
    @Binding var date:Date
    let entries: [DailyEntry]
    
    @State var showAddHabit: Bool = false
    
    @State private var counter: Int = 0
    @State private var audioPlayer2: AVAudioPlayer?
    
    @State private var showMessage = false // Controls the visibility of the message
    
    @State private var showAchievement = false
    @State private var currentAchievement: Achievement = .none
    
    var body: some View {
        ZStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink(destination: HabitDetailProgressView(date: date, habit:entry.habit)) {
                        HabitItemCell(item: entry.habit, entry: entry)
                            .contentShape(Rectangle())
                            .onChange(of: entry.isCompleted) { old, newValue in
                                changed(entry: entry, old, newValue)
                            }
                    }
                }
            }
            .overlay(alignment: .top) {
                let title = title(achievement: currentAchievement)
                let icon = icon(achievement: currentAchievement)
                AchievementBanner(title: title, icon: icon,  isPresented: $showAchievement)
            }
            .listStyle(.plain)
            .confettiCannon(trigger: $counter, num: 100, rainHeight: 250)
            
            VStack {
                // Overlay message
                if showMessage {
                    Text(motivationMessage())
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .fontWeight(.bold).rainbowRun()
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
        ModelData.shared.saveContext()
        
        if (date.isToday()) {
            
            let achievement = ModelData.shared.completedEntry(entry: entry)

            if achievement != .none {
                currentAchievement = achievement
                showAchievement = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showAchievement = false
                }
                // play achivement sound
                playSound(name: "achive-sound-4.caf")
                
            }
            
            if (new) {
                silenceTodaysNotification(identifier: entry.habit.id)
            } else {
                reScheduleWeekdayNotification(habitItem: entry.habit)
            }
        
            let contCompleted = entries.reduce(0) { $0 + ($1.isCompleted ? 1 : 0)}
            
            if (contCompleted == entries.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    counter += 1
                    playSound(name: "Balloon Pop.caf")
                    completeHabits()
                }
            }
        }
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
    DayHabitsListView(date: .constant(Date()), entries: entries)
}
