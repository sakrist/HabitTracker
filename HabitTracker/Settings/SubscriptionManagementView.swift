import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Text("Current Plan")
                        .font(.headline)
                    
                    Text(subscriptionService.currentPlan.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Show description of current benefits
                    Text(subscriptionService.currentPlan.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            if subscriptionService.currentPlan != .free {
                Section {
                    Button {
                        Task {
                            await manageSubscriptions()
                        }
                    } label: {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }
            }
            
            Section("Available Plans") {
                ForEach([SubscriptionOption.monthly, SubscriptionOption.yearly], id: \.self) { option in
                    if option != subscriptionService.currentPlan {
                        Button {
                            Task {
                                await purchaseSubscription(option)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.rawValue)
                                        .font(.headline)
                                    
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let product = storeManager.product(for: option) {
                                    Text(product.displayPrice)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(isLoading)
                    }
                }
            }
            
            Section {
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            
            // Terms and Privacy
            Section {
                Link(destination: URL(string: "https://www.example.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                Link(destination: URL(string: "https://www.example.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
        }
        .navigationTitle("Subscription")
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            Task {
                await storeManager.loadProducts()
                await subscriptionService.updateSubscriptionStatus()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func manageSubscriptions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                                return
                            }
            try await AppStore.showManageSubscriptions(in: window)
        } catch {
            alertTitle = "Error"
            alertMessage = "Could not open subscription management. Please try again later."
            showAlert = true
        }
    }
    
    private func purchaseSubscription(_ option: SubscriptionOption) async {
        isLoading = true
        defer { isLoading = false }
        
        let success = await subscriptionService.purchase(option: option)
        
        if success {
            alertTitle = "Success"
            alertMessage = "Your subscription has been updated to \(option.rawValue)!"
        } else {
            alertTitle = "Error"
            alertMessage = "There was a problem with your purchase. Please try again later."
        }
        
        showAlert = true
    }
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        let restored = await subscriptionService.restorePurchases()
        
        if restored {
            alertTitle = "Success"
            alertMessage = "Your purchases have been restored!"
        } else {
            alertTitle = "No Purchases Found"
            alertMessage = "No previous purchases were found to restore."
        }
        
        showAlert = true
    }
}

#Preview {

        NavigationView {
            SubscriptionManagementView()
        }
        
        NavigationView {
            SubscriptionManagementView()
        }
    
}
