//
//  InterstitialAdManager.swift
//  HabitTracker
//
//  Created by GitHub Copilot on 06/01/2026.
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var interstitialAd: InterstitialAd?
    @Published var isLoading = false
    
    private let adUnitID = AdConfiguration.interstitialAdUnitID
    private var adCounter = 0
    private let adFrequency = 3 // Show ad every 3rd time
    
    override init() {
        super.init()
        loadInterstitial()
    }
    
    func loadInterstitial() {
        guard !isLoading else { return }
        isLoading = true
        
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    self.interstitialAd = nil
                    return
                }
                
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showAdIfReady() -> Bool {
        // Only show ad if user is not ad-free
        guard !SubscriptionService.shared.isAdFree else {
            return false
        }
        
        // Increment counter and check frequency
        adCounter += 1
        guard adCounter % adFrequency == 0 else {
            return false
        }
        
        // Show ad if loaded
        guard let interstitialAd = interstitialAd,
              let rootViewController = UIApplication.shared.firstKeyWindow?.rootViewController else {
            loadInterstitial() // Preload next ad
            return false
        }
        
        interstitialAd.present(from: rootViewController)
        return true
    }
    
    // MARK: - FullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Preload next ad after dismissal
        loadInterstitial()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
        loadInterstitial()
    }
}
