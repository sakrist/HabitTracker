import Foundation
import SwiftUI

// Service to track and provide subscription status throughout the app
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published private(set) var currentPlan: SubscriptionOption = .free
    @Published private(set) var hasFullAccess = false
    @Published private(set) var isAdFree = false
    
    @AppStorage("SelectedSubscription") private var savedPlan: String = SubscriptionOption.free.rawValue
    
    init() {
        // Initialize from stored value
        if let option = SubscriptionOption(rawValue: savedPlan) {
            currentPlan = option
        }
        
        // Start monitoring StoreKit status
        Task {
            await updateSubscriptionStatus()
        }
    }
    
    func updateSubscriptionStatus() async {
        let storeManager = StoreManager.shared
        
        // First update purchased products
        await storeManager.updatePurchasedProducts()
        
        // Then determine current plan level
        if storeManager.hasLifetimePurchase {
            currentPlan = .lifetime
            hasFullAccess = true
            isAdFree = true
            savePlanStatus(.lifetime)
        } else if storeManager.hasYearlySubscription {
            currentPlan = .yearly
            hasFullAccess = true
            isAdFree = true
            savePlanStatus(.yearly)
        } else if storeManager.hasMonthlySubscription {
            currentPlan = .monthly
            hasFullAccess = true
            isAdFree = true
            savePlanStatus(.monthly)
        } else {
            // Free plan now has full access (only ads are different)
            currentPlan = .free
            hasFullAccess = true
            isAdFree = false
            savePlanStatus(.free)
        }
    }
    
    private func savePlanStatus(_ option: SubscriptionOption) {
        savedPlan = option.rawValue
    }
    
    
    // Purchase a subscription or non-consumable purchase
    func purchase(option: SubscriptionOption) async -> Bool {
        guard option != .free else { return true }
        
        do {
            let transaction = try await StoreManager.shared.purchase(option: option)
            if transaction != nil {
                await updateSubscriptionStatus()
                return true
            }
            return false
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    // Restore purchases
    func restorePurchases() async -> Bool {
        await StoreManager.shared.restorePurchases()
        await updateSubscriptionStatus()
        return hasFullAccess
    }
}
