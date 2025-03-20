//
//  ProgressCardView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 20/01/2025.
//

import SwiftUI

struct ProgressCardView: View {
    let currentStreak: Int
    let completionRate: Int // In percentage

    var body: some View {
        HStack {
            // Current Streak Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(currentStreak) days")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Completion Rate Section
            VStack(alignment: .trailing, spacing: 4) {
                Text("Completion Rate")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(completionRate)%")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
//        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct ProgressCardView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCardView(currentStreak: 7, completionRate: 85)
            .previewLayout(.sizeThatFits)
    }
}
