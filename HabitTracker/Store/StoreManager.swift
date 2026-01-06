import StoreKit
import Foundation
import SwiftUI

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case networkError
    case userCancelled
    case unknown(Error?)
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product identifiers from your StoreKit configuration
    private let monthlySubscriptionID = "com.sakrist.HabitTracker.monthly"
    private let yearlySubscriptionID = "com.sakrist.HabitTracker.yearly"
    private let lifetimeID = "com.sakrist.HabitTracker.lifetime" // non-consumable purchase
    
    // Published properties for observing in UI
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIdentifiers = Set<String>()
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = [monthlySubscriptionID, yearlySubscriptionID, lifetimeID]
            let storeProducts = try await Product.products(for: productIDs)
            
            // Sort products by price (monthly first, then yearly, then lifetime)
            products = storeProducts.sorted {
                // If both are non-subscriptions or both are subscriptions, sort by price
                if ($0.type == .nonConsumable && $1.type == .nonConsumable) ||
                   ($0.type != .nonConsumable && $1.type != .nonConsumable) {
                    return $0.price < $1.price
                }
                // Put subscriptions before non-consumables
                return $0.type != .nonConsumable
            }
            
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Functions
    
    func purchase(option: SubscriptionOption) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        let productID: String
        
        switch option {
        case .monthly:
            productID = monthlySubscriptionID
        case .yearly:
            productID = yearlySubscriptionID
        case .lifetime:
            productID = lifetimeID
        case .free:
            // Free tier doesn't require purchase
            return nil
        }
        
        guard let product = products.first(where: { $0.id == productID }) else {
            throw StoreError.productNotFound
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                let transaction = try checkVerified(verification)
                
                // Update the app's state based on the purchased product
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                return transaction
                
            case .userCancelled:
                throw StoreError.userCancelled
                
            case .pending:
                errorMessage = "Purchase is pending approval."
                return nil
                
            default:
                throw StoreError.unknown(nil)
            }
            
        } catch {
            // Handle errors from purchase or verification
            if let storeError = error as? StoreError {
                throw storeError
            } else {
                throw StoreError.unknown(error)
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Status Management
    
    func updatePurchasedProducts() async {
        var purchasedProducts = Set<String>()
        
        print("🔍 StoreManager: Checking current entitlements...")
        
        // Check for subscription status
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Add to purchased products if not expired
                if transaction.revocationDate == nil {
                    purchasedProducts.insert(transaction.productID)
                    print("✅ StoreManager: Found active purchase: \(transaction.productID)")
                } else {
                    print("⚠️ StoreManager: Found revoked purchase: \(transaction.productID)")
                }
                
            } catch {
                print("❌ StoreManager: Transaction verification failed: \(error)")
            }
        }
        
        print("📊 StoreManager: Total active purchases: \(purchasedProducts.count)")
        print("   - Monthly: \(purchasedProducts.contains(monthlySubscriptionID))")
        print("   - Yearly: \(purchasedProducts.contains(yearlySubscriptionID))")
        print("   - Lifetime: \(purchasedProducts.contains(lifetimeID))")
        
        self.purchasedIdentifiers = purchasedProducts
    }
    
    // MARK: - Subscription Status Checks
    
    var isSubscribed: Bool {
        hasActiveSubscription || hasLifetimePurchase
    }
    
    var hasActiveSubscription: Bool {
        hasMonthlySubscription || hasYearlySubscription
    }
    
    var hasYearlySubscription: Bool {
        purchasedIdentifiers.contains(yearlySubscriptionID)
    }
    
    var hasMonthlySubscription: Bool {
        purchasedIdentifiers.contains(monthlySubscriptionID)
    }
    
    var hasLifetimePurchase: Bool {
        purchasedIdentifiers.contains(lifetimeID)
    }
    
    // MARK: - Product Helpers
    
    func product(for option: SubscriptionOption) -> Product? {
        switch option {
        case .monthly:
            return products.first(where: { $0.id == monthlySubscriptionID })
        case .yearly:
            return products.first(where: { $0.id == yearlySubscriptionID })
        case .lifetime:
            return products.first(where: { $0.id == lifetimeID })
        case .free:
            return nil
        }
    }
    
    func price(for option: SubscriptionOption) -> String {
        guard let product = product(for: option) else {
            return option == .free ? "Free" : "N/A"
        }
        return product.displayPrice
    }
    
    func priceDecimal(for option: SubscriptionOption) -> Decimal {
        guard let product = product(for: option) else {
            return 0
        }
        return product.price
    }
    
    func periodText(for option: SubscriptionOption) -> String {
        guard let product = product(for: option) else {
            return ""
        }
        
        if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .day where subscription.subscriptionPeriod.value == 1:
                return "per day"
            case .day:
                return "per \(subscription.subscriptionPeriod.value) days"
            case .week where subscription.subscriptionPeriod.value == 1:
                return "per week"
            case .week:
                return "per \(subscription.subscriptionPeriod.value) weeks"
            case .month where subscription.subscriptionPeriod.value == 1:
                return "per month"
            case .month:
                return "per \(subscription.subscriptionPeriod.value) months"
            case .year where subscription.subscriptionPeriod.value == 1:
                return "per year"
            case .year:
                return "per \(subscription.subscriptionPeriod.value) years"
            @unknown default:
                return "subscription"
            }
        }
        
        return ""
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        print("🔄 StoreManager: Starting restore purchases...")
        
        // This will automatically update purchasedIdentifiers
        await updatePurchasedProducts()
        
        print("📦 StoreManager: Restore complete. Found \(purchasedIdentifiers.count) purchases")
        
        // Show a message to the user
        if purchasedIdentifiers.isEmpty {
            errorMessage = "No previous purchases found to restore."
            print("ℹ️ StoreManager: No purchases to restore")
        } else {
            errorMessage = "Your purchases have been restored!"
            print("✅ StoreManager: Purchases restored: \(purchasedIdentifiers)")
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to purchase.
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update the app's state to reflect the completed transaction
                    await self.updatePurchasedProducts()
                    
                    // Always finish a transaction
                    await transaction.finish()
                    
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
}
