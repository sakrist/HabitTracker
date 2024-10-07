//
//  ContentView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DailyHabitListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
