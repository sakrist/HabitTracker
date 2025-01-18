//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 06/10/2024.
//

import Foundation
import SwiftUI
import SwiftData
import ConfettiSwiftUI
import AVFoundation

struct HabitsList: View {
    let date:Date
    let entries: [DailyEntry]
    
    @State private var counter: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayer2: AVAudioPlayer?
    
    var body: some View {
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
    }
    
    private func changed(entry:DailyEntry, _ old:Bool, _ new:Bool) {
        ModelData.shared.saveContext()
        if (new) {
            playSound()
            silenceTodaysNotification(identifier: entry.habit.id)
        } else {
            reScheduleWeekdayNotification(habitItem: entry.habit)
        }
        
        var entriesFiltered = entries.filter { $0.isCompleted }
        if (entriesFiltered.count == entries.count) {
            // dispatch to main queue after 0.5 sec
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                counter += 1
                playPopSound()
            }
        }
    }
    
    // Set up the audio player
    private func setupAudioPlayer() {
        guard let soundURL =  Bundle.main.url(forResource: "sparkle", withExtension: "wav") else {
            print("Audio file not found.")
            return
        }

        do {
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
            audioPlayer2 = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer2?.prepareToPlay()
        } catch {
            print("Error initializing audio player: \(error)")
        }
        audioPlayer2?.play()
    }
    
    
}

struct DailyHabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    
    @State private var entries: [DailyEntry] = []
    @State private var selectedDate: Date = Date()  // The currently selected date

    @State private var counter: Int = 0
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Display the selected date
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                        entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    
                    Spacer()
                    
                    Text(selectedDate, style: .date)  // Show the current selected date
                        .font(.title.bold())
                    
                    Spacer()
                    
                    if !selectedDate.isToday() {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                            entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                        }) {
                            Image(systemName: "arrow.right")
                        }
                    } else {
                        Image(systemName: "arrow.right").opacity(0)
                    }
                }
                .padding()

                VStack {
                    if (entries.count == 0) {
                        // show button add habits which will navigate to Habits tab
                        Spacer()
                        Text("Start by adding habits you already do daily.\n")
                        
                        Text(" · · · ")
                        
                        Text("If you want to build a new habits, \nstart by adding one habit at a time.\n")
                            .multilineTextAlignment(.center)
                        
                        // 3 dots
                        Text(" · · · ")
                        
                        Text("Science says - \nit takes around 66 days to make a habit stick.\n")
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // navigate to Habits tab
                            selectedTab = 1
                        }) {
                            Text("Add habits")
                        }
                        Spacer()
                        Spacer()
                    } else {
                        HabitsList(date: selectedDate, entries: entries)
                    }
                }
                .onAppear {
                    entries = fetchHabitEntries(modelContext: modelContext, for: selectedDate)
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    
}

#Preview {
    let model = ModelData.shared
    DailyHabitListView(selectedTab: .constant(0))
        .environment(ModelData.shared)
        .modelContainer(model.modelContainer)
}
