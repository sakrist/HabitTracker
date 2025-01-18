//
//  NotificationCenter.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 18/01/2025.
//

import UserNotifications
import UIKit

@MainActor
func requestNotificationPermission() {
    let center = UNUserNotificationCenter.current()
    let userDefaultsKey = "hasAskedNotificationPermission"
        
    // Check if the user has already been asked
    let hasAsked = UserDefaults.standard.bool(forKey: userDefaultsKey)
    
    if (!hasAsked) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting permission: \(error)")
            }
            print("Permission granted: \(granted)")
        }
    } else {
        checkNotificationPermission { newValue in
            ModelData.shared.notificationsEnabled = newValue
        }
    }
}

func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
        DispatchQueue.main.async {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                // Notifications are allowed
                completion(true)
            case .denied, .notDetermined:
                // Notifications are not allowed or user hasn't decided yet
                completion(false)
            @unknown default:
                // Handle any future cases
                completion(false)
            }
        }
    }
}

func openAppSettings() {
    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL) { success in
            if success {
                print("Opened app settings.")
            }
        }
    }
}


func reScheduleWeekdayNotification(habitItem: HabitItem) {
    cancelNotifications(baseIdentifier: habitItem.id)
    scheduleWeekdayNotification(habitItem: habitItem)
}

func scheduleWeekdayNotification(habitItem: HabitItem) {
    if (habitItem.isTimeSensitive && habitItem.time != nil) {
        scheduleWeekdayNotification(identifier: habitItem.id,
                                    title: habitItem.title,
                                    body: "Time for \(habitItem.title)",
                                    date: habitItem.time!,
                                    weekdays: habitItem.calendarWeekdays())
    }
}

func scheduleWeekdayNotification(
    identifier: String,
    title: String,
    body: String,
    date: Date,
    weekdays: [Int] // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
) {
    let center = UNUserNotificationCenter.current()
    
    for weekday in weekdays {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Set up the trigger for specific weekday and time
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        dateComponents.weekday = weekday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create a unique identifier for each weekday notification
        let weekdayIdentifier = "\(identifier)_\(weekday)"
        
        let request = UNNotificationRequest(identifier: weekdayIdentifier, content: content, trigger: trigger)
        
        // Add the notification request
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification for weekday \(weekday): \(error)")
            } else {
                print("Notification scheduled for weekday \(weekday) with identifier: \(weekdayIdentifier)")
            }
        }
    }
}

func cancelNotifications(baseIdentifier: String) {
    let weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    cancelWeekdayNotifications(baseIdentifier: baseIdentifier, weekdays: weekdays)
}

func cancelWeekdayNotifications(baseIdentifier: String, weekdays: [Int]) {
    let center = UNUserNotificationCenter.current()
    let identifiers = weekdays.map { "\(baseIdentifier)_\($0)" }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
}


func cancelAllNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
}



// TODO: does not work, need to think how to reschedule if completed.
/// Cancel today's notification but keep it scheduled for the next occurrence
func silenceTodaysNotification(identifier: String) {
    let center = UNUserNotificationCenter.current()
    
    let calendar = Calendar.current
    let today = Date()
    let dayOfWeek = calendar.component(.weekday, from: today)
    let todayIdentifier = "\(identifier)_\(dayOfWeek)"
    
    center.getPendingNotificationRequests { requests in
        // Filter the notification with the given identifier
        let matchingRequests = requests.filter { $0.identifier == todayIdentifier }
        
        if !matchingRequests.isEmpty {
            // Cancel the notification for today
            center.removePendingNotificationRequests(withIdentifiers: [todayIdentifier])
            print("Today's notification with identifier '\(todayIdentifier)' has been silenced.")
            
            // Reschedule for future occurrences if necessary
            if let request = matchingRequests.first,
               let trigger = request.trigger as? UNCalendarNotificationTrigger,
               trigger.repeats {
                center.add(request) { error in
                    if let error = error {
                        print("Error rescheduling notification: \(error)")
                    } else {
                        print("Notification rescheduled for the next occurrence.")
                    }
                }
            }
        } else {
            print("No matching notification found to silence.")
        }
    }
}
