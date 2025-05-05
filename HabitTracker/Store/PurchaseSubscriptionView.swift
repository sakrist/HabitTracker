//
//  PurchaseSubscriptionView.swift
//  HabitTracker
//

import SwiftUI

struct PurchaseSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubscription: SubscriptionOption
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = "Failed to complete the purchase. Please try again later."
    
    let hideFreeOption: Bool
    let onComplete: ((Bool) -> Void)?
    
    init(initialOption: SubscriptionOption = .monthly, hideFreeOption: Bool = true, onComplete: ((Bool) -> Void)? = nil) {
        _selectedSubscription = State(initialValue: initialOption)
        self.hideFreeOption = hideFreeOption
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack {
            
            // Custom OnboardingSubscriptionView
            OnboardingSubscriptionView(
                title: "Upgrade Your Plan",
                selectedOption: $selectedSubscription,
                hideFreeOption: hideFreeOption
            )
            .disabled(isLoading)
            
            // Purchase and Cancel buttons
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView("Processing...")
                        .padding()
                } else {
                    Button(action: completePurchase) {
                        Text("Purchase")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading || selectedSubscription == .free)
                    
                    Button(action: {
                        onComplete?(false)
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .alert("Purchase Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func completePurchase() {
        guard selectedSubscription != .free else { return }
        
        isLoading = true
        
        Task {
            do {
                let success = await SubscriptionService.shared.purchase(option: selectedSubscription)
                
                await MainActor.run {
                    isLoading = false
                    
                    if success {
                        onComplete?(true)
                        dismiss()
                    } else {
                        errorMessage = "Failed to complete the purchase. Please try again later."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

struct CustomSubscriptionView: View {
    @Binding var selectedOption: SubscriptionOption
    @StateObject private var storeManager = StoreManager.shared
    var hideFreeOption: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Only show free option if not hidden
                if !hideFreeOption {
                    SubscriptionCard(
                        option: .free,
                        isSelected: selectedOption == .free,
                        onSelect: { selectedOption = .free }
                    )
                }
                
                // Monthly option
                SubscriptionCard(
                    option: .monthly,
                    isSelected: selectedOption == .monthly,
                    price: storeManager.price(for: .monthly),
                    onSelect: { selectedOption = .monthly }
                )
                
                // Yearly option with best value badge
                SubscriptionCard(
                    option: .yearly,
                    isSelected: selectedOption == .yearly,
                    price: storeManager.price(for: .yearly),
                    onSelect: { selectedOption = .yearly },
                    saveBadge: calculateYearlySavings()
                )
                
                // Lifetime option
                SubscriptionCard(
                    option: .lifetime,
                    isSelected: selectedOption == .lifetime,
                    price: storeManager.price(for: .lifetime),
                    onSelect: { selectedOption = .lifetime },
                    saveBadge: "BEST VALUE"
                )
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 500)
        .onAppear {
            // Load prices when view appears
            Task {
                await storeManager.loadProducts()
            }
        }
    }
    
    private func calculateYearlySavings() -> String {
        let monthlyPrice = storeManager.priceDecimal(for: .monthly)
        let yearlyPrice = storeManager.priceDecimal(for: .yearly)
        
        if monthlyPrice > 0 && yearlyPrice > 0 {
            // Calculate yearly equivalent cost (12 months)
            let yearlyEquivalent = monthlyPrice * 12
            
            // Calculate savings percentage
            if yearlyEquivalent > yearlyPrice {
                let savings = yearlyEquivalent - yearlyPrice
                let savingsPercent = (savings / yearlyEquivalent) * 100
                
                // Convert to NSDecimalNumber for rounding
                let decimalNumber = NSDecimalNumber(decimal: savingsPercent)
                let roundedDecimal = decimalNumber.rounding(accordingToBehavior: nil)
                let roundedPercent = Int(truncating: roundedDecimal)
                
                if roundedPercent > 0 {
                    return "SAVE \(roundedPercent)%"
                }
            }
        }
        
        return ""
    }
}

#Preview {
    PurchaseSubscriptionView()
}
