import Foundation
import SwiftUI

// Service to track and provide subscription status throughout the app
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    // Max habits allowed for free users
    let maxFreeHabits = 5
    
    @Published private(set) var currentPlan: SubscriptionOption = .free
    @Published private(set) var hasFullAccess = false
    
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
            savePlanStatus(.lifetime)
        } else if storeManager.hasYearlySubscription {
            currentPlan = .yearly
            hasFullAccess = true
            savePlanStatus(.yearly)
        } else if storeManager.hasMonthlySubscription {
            currentPlan = .monthly
            hasFullAccess = true
            savePlanStatus(.monthly)
        } else {
            // Default to free if no active subscription or lifetime purchase
            currentPlan = .free
            hasFullAccess = false
            savePlanStatus(.free)
        }
    }
    
    private func savePlanStatus(_ option: SubscriptionOption) {
        savedPlan = option.rawValue
    }
    
    // Check if user can add more habits
    func canAddMoreHabits(currentCount: Int) -> Bool {
        if currentPlan == .free {
            return currentCount < maxFreeHabits
        }
        return true
    }
    
    // Check if health integration is allowed
    func canUseHealthIntegration(healthHabitsCount: Int) -> Bool {
        if currentPlan == .free {
            return healthHabitsCount < 1
        }
        return true
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
