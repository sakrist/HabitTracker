//
//  OnboardingSubscriptionView.swift
//  HabitTracker
//

import SwiftUI

struct OnboardingSubscriptionView: View {
    @Binding var selectedOption: SubscriptionOption
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Select the option that works best for you")
                .font(.subheadline)
                .foregroundColor(.secondary)
//                .padding(.bottom)
            
            // Subscription options
            VStack(spacing: 15) {
                // Free tier
                SubscriptionCard(
                    option: .free,
                    isSelected: selectedOption == .free,
                    action: { selectedOption = .free }
                )
                
                // Monthly subscription
                SubscriptionCard(
                    option: .monthly,
                    isSelected: selectedOption == .monthly,
                    action: { selectedOption = .monthly }
                )
                
                // Yearly subscription (best value)
                SubscriptionCard(
                    option: .yearly,
                    isSelected: selectedOption == .yearly,
//                    isBestValue: true,
                    action: { selectedOption = .yearly }
                )
                
//                // Lifetime option
//                SubscriptionCard(
//                    option: .lifetime,
//                    isSelected: selectedOption == .lifetime,
//                    action: { selectedOption = .lifetime }
//                )
            }
            .padding(.horizontal)
            
//            Spacer()
            
            // Disclaimer text
            Group {
                Text("Payments will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .padding()
    }
}

struct SubscriptionCard: View {
    let option: SubscriptionOption
    let isSelected: Bool
    var isBestValue: Bool = false
    let action: () -> Void
    
    var backgroundColor: Color {
        switch option {
        case .free:
            return Color(.systemGray6)
        case .monthly:
            return Color.blue.opacity(0.1)
        case .yearly:
            return Color.blue.opacity(0.15)
        case .lifetime:
            return Color.purple.opacity(0.15)
        }
    }
    
    var textColor: Color {
        switch option {
        case .free:
            return .primary
        case .monthly, .yearly:
            return .blue
        case .lifetime:
            return .purple
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.rawValue)
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Text(option.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? textColor : .gray.opacity(0.5))
                        .font(.system(size: 22))
                }
                
                // Show benefits for the selected option
                if isSelected {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(option.benefits, id: \.self) { benefit in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor)
                                
                                Text(benefit)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? textColor : Color.clear, lineWidth: 2)
                    
                    if isBestValue {
                        Text("BEST VALUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .offset(y: -12)
                            .position(x: 70, y: 0)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingSubscriptionView(selectedOption: .constant(.monthly))
}
