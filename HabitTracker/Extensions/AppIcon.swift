//
//  AppIcon.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 20/04/2025.
//

import SwiftUI

extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}

struct AppIcon: View {
    var body: some View {
        if let iconFileName = Bundle.main.iconFileName,
           let uiImage = UIImage(named: iconFileName) {
            Image(uiImage: uiImage)
                .resizable() // Make it resizable by default for better usability
        } else {
            // Fallback to a system icon if app icon can't be loaded
            Image(systemName: "app.fill")
                .resizable()
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppIcon()
            .frame(width: 60, height: 60)
            .cornerRadius(12)
        
        AppIcon()
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .shadow(radius: 5)
        
        AppIcon()
            .frame(width: 120, height: 120)
            .opacity(0.7)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.red, lineWidth: 2))
    }
    .padding()
}
