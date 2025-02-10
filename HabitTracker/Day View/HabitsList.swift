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
import Shiny
import RainbowUI

struct HabitsList: View {
    let date:Date
    let entries: [DailyEntry]
    
    @State private var counter: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayer2: AVAudioPlayer?
    
    @State private var showMessage = false // Controls the visibility of the message
    @State private var message = "Well done for Today!"
    
    var body: some View {
        ZStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink(destination: HabitMonthView(date: date, habit:entry.habit)) {
                        HabitItemCell(item: entry.habit, entry: entry)
                            .contentShape(Rectangle())
                            .onChange(of: entry.isCompleted) { old, newValue in
                                changed(entry: entry, old, newValue)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .confettiCannon(trigger: $counter, num: 100, rainHeight: 300)
            .onAppear {
                setupAudioPlayer()
            }
            
            VStack {
                // Overlay message
//                if showMessage {
                    Text(message)
                        .font(.largeTitle)
                        .fontWeight(.bold).rainbowRun()
                        .opacity(showMessage ? 1 : 0) // Fade in and out
//                }
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
            if (new) {
                silenceTodaysNotification(identifier: entry.habit.id)
            } else {
                reScheduleWeekdayNotification(habitItem: entry.habit)
            }
        
            let contCompleted = entries.reduce(0) { $0 + ($1.isCompleted ? 1 : 0)}
            
            if (contCompleted == entries.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    counter += 1
                    playPopSound()
                    completeHabits()
                }
            }
        }
    }
    
    // Set up the audio player
    private func setupAudioPlayer() {
        guard let soundURL =  Bundle.main.url(forResource: "clang", withExtension: "wav") else {
            print("Audio file not found.")
            return
        }

        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance()
                .setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error initializing audio player: \(error)")
        }
    }

    // Play the audio
    private func playSound() {
        audioPlayer?.play()
    }
    
    // Set up the audio player
    private func playPopSound() {
        guard let soundURL =  Bundle.main.url(forResource: "Balloon Pop", withExtension: "caf") else {
            print("Audio file not found.")
            return
        }

        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance()
                .setActive(true)
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
    HabitsList(date: Date(),
               entries: entries)
}
