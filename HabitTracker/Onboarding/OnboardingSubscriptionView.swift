//
//  OnboardingSubscriptionView.swift
//  HabitTracker
//

import SwiftUI
import StoreKit


struct OnboardingSubscriptionView: View {
    var title: String = "Choose Your Plan"
    @Binding var selectedOption: SubscriptionOption
    @StateObject private var storeManager = StoreManager.shared
    var hideFreeOption: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Select the best plan for your habit tracking journey")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    if !hideFreeOption {
                        // Free option
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
                .padding(.vertical, 2)
            }
            
            if storeManager.isLoading {
                ProgressView()
            }
            
            if !storeManager.isSubscribed {
                HStack {
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.purchasedIdentifiers.isEmpty {
                                storeManager.errorMessage = "No previous purchases found to restore."
                            } else {
                                storeManager.errorMessage = "Your purchases have been restored!"
                            }
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                    Spacer()
                    Button(action: {
                        redeemCode()
                    }) {
                        Text("Redeem Code")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }.padding(.horizontal, 20)
            }
            
            VStack(spacing: 4) {
                Text("By subscribing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Link("EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("Privacy Policy", destination: URL(string: "https://habit-app.sakrist.com/privacy/")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // Load prices when view appears
            Task {
                await storeManager.loadProducts()
            }
        }
    }
    
    private var footerText: String {
        (selectedOption == .monthly || selectedOption == .yearly) ?
            "You can change your plan at any time in the app settings" :
            (selectedOption == .lifetime ? "One-time payment, no recurring charges" : "Free plan with basic features")
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
    
    private func redeemCode() {
        if let window = UIApplication.shared.connectedScenes.first {
            Task {
                // Use StoreKit's recommended API instead of direct URL
                try? await AppStore.presentOfferCodeRedeemSheet(in: window as! UIWindowScene)
                await StoreManager.shared.restorePurchases()
            }
        }
    }
    
}

struct SubscriptionCard: View {
    let option: SubscriptionOption
    let isSelected: Bool
    var price: String = ""
    let onSelect: () -> Void
    var saveBadge: String = ""
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(option.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !price.isEmpty && option != .free {
                        if option == .monthly {
                            Text("\(price) / month")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        } else if option == .yearly {
                            Text("\(price) / year")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        } else {
                            Text(price)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                    }
                    
                    // Just show a few key benefits
//                    VStack(alignment: .leading, spacing: 4) {
//                        ForEach(option.benefits.prefix(3), id: \.self) { benefit in
//                            Label(benefit, systemImage: "checkmark.circle.fill")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                    .padding(.top, 4)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .overlay(alignment: .topTrailing) {
                if !saveBadge.isEmpty {
                    Text(saveBadge)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(option == .lifetime ? Color.green : Color.orange)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingSubscriptionView(selectedOption: .constant(.monthly))
}
