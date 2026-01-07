//
//  BannerAdView.swift
//  HabitTracker
//
//  Created by GitHub Copilot on 06/01/2026.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    @Binding var isLoaded: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.firstKeyWindow?.rootViewController
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        @Binding var isLoaded: Bool
        
        init(isLoaded: Binding<Bool>) {
            _isLoaded = isLoaded
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
            isLoaded = true
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
            isLoaded = false
        }
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
