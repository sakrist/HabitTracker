//
//  UIApplication.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 04/04/2025.
//

#if os(macOS)

import Cocoa

typealias UIApplication = NSApplication

extension UIApplication {
    
    func canOpenURL(_ url: URL) -> Bool {
        return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }
    
    func open(_ url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        let success = NSWorkspace.shared.open(url)
        completionHandler?(success)
    }
}

#endif

