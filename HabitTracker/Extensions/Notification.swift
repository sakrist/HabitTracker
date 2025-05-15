//
//  Notification.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 20/04/2025.
//

import Foundation
import UIKit

extension NotificationCenter {
    
    func postActive() {
        #if canImport(UIKit)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif canImport(AppKit)
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        #else
        fatalError("Unsupported platform")
        #endif
    }
    
}
