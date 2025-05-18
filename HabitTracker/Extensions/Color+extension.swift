//
//  Untitled.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 26/09/2024.
//

import Foundation
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
typealias AColor = UIColor
#elseif os(macOS)
typealias AColor = NSColor
#endif

#if os(macOS)
extension NSColor {
    static let systemGray6 = NSColor(named: "systemGray6") ?? NSColor.gray
}
#endif

#if os(watchOS)
extension UIColor {
    static let systemBackground: UIColor = .white
    static let systemGray6: UIColor = .gray
}
#endif
    
    

extension Color {
    // Convert Color to hex string
    func toHex() -> String {
        guard let components = AColor(self).cgColor.components else {
            return "#000000"
        }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // Initialize Color from hex string
    init?(hex: String) {
        let r, g, b: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        
        guard hexColor.count == 6 else { return nil }
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            
            self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
            return
        }
        return nil
    }
    
    // Get a random color
    static func random() -> Color {
        return Color(red: .random(in: 0...1),
                     green: .random(in: 0...1),
                     blue: .random(in: 0...1))
    }
}
