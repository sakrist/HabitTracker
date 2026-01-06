//
//  AdConfiguration.swift
//  HabitTracker
//
//  Created by GitHub Copilot on 06/01/2026.
//

import Foundation

enum AdConfiguration {
    
    // Banner Ad Unit IDs
    static var bannerAdUnitID: String {
#if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // Test banner
#else
        return "ca-app-pub-1267260663063670/4045817441" // Production banner
#endif
    }
    
    // Interstitial Ad Unit IDs
    static var interstitialAdUnitID: String {
#if DEBUG
        return "ca-app-pub-3940256099942544/4411468910" // Test interstitial
#else
        return "ca-app-pub-1267260663063670/7797020884" // Production interstitial
#endif
    }
    
    // App ID (from Info.plist)
    static let appID = "ca-app-pub-1267260663063670~8375944694"
}
