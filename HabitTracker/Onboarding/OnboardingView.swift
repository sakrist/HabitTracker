//
//  OnboardingView.swift
//  HabitTracker
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData
    
    @State private var currentPage = 0
    @State private var selectedHabits: [Bool] = Array(repeating: false, count: commonHabits.count)
    @State private var selectedSubscription: SubscriptionOption = .free
    @State private var isLoading = false
    
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack {
            // Page indicator
            HStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top)
            
            // Page content
            TabView(selection: $currentPage) {
                OnboardingIntroView()
                    .tag(0)
                
                OnboardingHabitsView(selectedHabits: $selectedHabits)
                    .tag(1)
                
                OnboardingSubscriptionView(selectedOption: $selectedSubscription)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .padding()
                } else {
                    Spacer()
                        .frame(width: 80)
                }
                
                Spacer()
                
                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.bottom)
        }
        .padding()
    }
    
    private func completeOnboarding() {
        // Purchase subscription if needed
        if selectedSubscription != .free {
            Task {
                isLoading = true
                let purchased = await SubscriptionService.shared.purchase(option: selectedSubscription)
                
                if !purchased {
                    // Fall back to free plan if purchase fails
                    selectedSubscription = .free
                }
                
                await MainActor.run {
                    isLoading = false
                    
                    // Continue with habit creation and completion
                    createSelectedHabits()
                    
                    // Save subscription choice
                    UserDefaults.standard.set(selectedSubscription.rawValue, forKey: "SelectedSubscription")
                    
                    // Mark onboarding as completed
                    UserDefaults.standard.set(true, forKey: "OnboardingCompleted")
                    
                    // Dismiss onboarding
                    showOnboarding = false
                }
            }
        } else {
            // If free plan, just continue with habit creation
            createSelectedHabits()
            
            // Save subscription choice
            UserDefaults.standard.set(selectedSubscription.rawValue, forKey: "SelectedSubscription")
            
            // Mark onboarding as completed
            UserDefaults.standard.set(true, forKey: "OnboardingCompleted")
            
            // Dismiss onboarding
            showOnboarding = false
        }
    }
    
    private func createSelectedHabits() {
        // Create selected habits
        addSelectedHabits()
    }
    
    private func addSelectedHabits() {
        // First, create habits but don't yet request health permissions
        var createdHabits: [HabitItem] = []
        
        for (index, isSelected) in selectedHabits.enumerated() {
            if isSelected && index < commonHabits.count {
                let habit = commonHabits[index]
                
                // Create new habit
                let newHabit = HabitItem(
                    title: habit.title,
                    color: habit.color,
                    category: modelData.defaultCategory(),
                    timestamp: Date()
                )
                
                // Set appropriate habit properties
                newHabit.weekdays = Set(HabitItem.Weekday.allCases)
                newHabit.healthType = habit.healthType
                newHabit.order = index
                
                // Insert into data model
                modelContext.insert(newHabit)
                createdHabits.append(newHabit)
            }
        }
        
        // Save initial context
        ModelData.shared.saveContext()
        
        // Now request health permissions for all health-enabled habits at once
        let healthHabits = createdHabits.filter { $0.healthType != nil && $0.healthType != .none }
        
        if !healthHabits.isEmpty {
            Task {
                // Request health authorizations in bulk
                let _ = await withCheckedContinuation { continuation in
                    Health.shared.requestBulkHealthAuthorization(for: healthHabits) { result in
                        continuation.resume(returning: result)
                    }
                }
                
                // Set up background delivery for authorized habits
                for habit in healthHabits {
                    if Health.shared.verifyHealthAuthorization(for: habit) {
                        Health.shared.enableHabitBackgroundDelivery(habit: habit) { _ in }
                    } else {
                        // If authorization failed, remove health integration
                        habit.healthType = HealthType.none
                    }
                }
                
                // Save again after authorizations
                await MainActor.run {
                    ModelData.shared.saveContext()
                    NotificationCenter.default.postActive()
                }
            }
        }
    }
}

// Common habits that will be shown in the second onboarding screen
struct CommonHabit {
    let title: String
    let color: String
    let healthType: HealthType
    let icon: String
    let description: String
}

let commonHabits: [CommonHabit] = [
    CommonHabit(
        title: "Morning Run",
        color: Color.blue.toHex(),
        healthType: .workout(.running),
        icon: "figure.run",
        description: "Start your day with a refreshing run"
    ),
    CommonHabit(
        title: "Drink Water",
        color: Color.cyan.toHex(),
        healthType: .quantity(.dietaryWater),
        icon: "drop.fill",
        description: "Stay hydrated throughout the day"
    ),
    CommonHabit(
        title: "Meditation",
        color: Color.purple.toHex(),
        healthType: .category(.mindfulSession, .meditate),
        icon: "brain.head.profile",
        description: "Take time to clear your mind"
    ),
    CommonHabit(
        title: "Read Book",
        color: Color.orange.toHex(),
        healthType: .none,
        icon: "book.fill",
        description: "Expand your knowledge daily"
    ),
    CommonHabit(
        title: "Gym",
        color: Color.red.toHex(),
        healthType: .workout(.traditionalStrengthTraining),
        icon: "dumbbell.fill",
        description: "Stay strong with regular gym workouts"
    ),
    CommonHabit(
        title: "Floss",
        color: Color.mint.toHex(),
        healthType: .none,
        icon: "mouth.fill",
        description: "Maintain good dental hygiene"
    ),
    CommonHabit(
        title: "Tooth brushing",
        color: Color.teal.toHex(),
        healthType: .category(.toothbrushingEvent),
        icon: "mouth.fill",
        description: "Keep your teeth clean and healthy"
    ),
    CommonHabit(
        title: "Eat Vegetables",
        color: Color.green.toHex(),
        healthType: .none,
        icon: "carrot.fill",
        description: "Ensure you get proper nutrition"
    )
]

enum SubscriptionOption: String, CaseIterable {
    case free = "Free"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case lifetime = "Lifetime"
    
    var description: String {
        switch self {
        case .free:
            return "Up to 5 habits, one health habit, basic features"
        case .monthly:
            return "All features unlocked"
        case .yearly:
            return "All features unlocked"
        case .lifetime:
            return "One-time purchase, all features forever"
        }
    }
    
    var isPurchase: Bool {
        return self == .lifetime
    }
    
    var isSubscription: Bool {
        return self == .monthly || self == .yearly
    }
    
    var benefits: [String] {
        switch self {
        case .free:
            return [
                "Up to 5 habits",
                "Basic tracking",
                "Daily progress view"
            ]
        default:
            return [
                "Unlimited habits",
                "Health integrations",
                "Import/export capabilities",
                "Timeline view",
                "More achievements to unlock",
                "All future improvements",
            ]
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environment(ModelData.shared)
        .modelContainer(SampleData.shared.modelContainer)
}
