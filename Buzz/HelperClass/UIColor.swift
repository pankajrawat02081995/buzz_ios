//
//  UIColor.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import UIKit

extension UIColor {
    
    // MARK: - Custom Colors
    
    static var ThemeOrangeStart: UIColor {
        return UIColor(named: "ThemeOrangeStart") ?? UIColor()
    }
    
    static var ThemeOrangeEnd: UIColor {
        return UIColor(named: "ThemeOrangeEnd") ?? UIColor()
    }
    
    static var TextWhite: UIColor {
        return UIColor(named: "TextWhite") ?? UIColor()
    }
    
    static var TextBlack: UIColor {
        return UIColor(named: "TextBlack") ?? UIColor()
    }
    
    static var BoarderColor: UIColor {
        return UIColor(named: "BoarderColor") ?? UIColor()
    }
    
    static var AppLightGray: UIColor {
        return UIColor(named: "AppLightGray") ?? UIColor()
    }
  
    // MARK: - Custom HEX Support (if needed)
    
    static func fromHex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor? {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") { hexFormatted.removeFirst() }
        guard hexFormatted.count == 6,
              let rgb = UInt32(hexFormatted, radix: 16) else { return nil }
        
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: alpha
        )
    }
    
    // MARK: - Private Helpers
    
    private static func color(named name: String) -> UIColor? {
        return UIColor(named: name)
    }
}
