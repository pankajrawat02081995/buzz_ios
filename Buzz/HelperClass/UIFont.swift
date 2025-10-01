//
//  UIFont.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import UIKit

public extension CGFloat {
    /// Automatically scales font size for iPad
    var autoScaledForDevice: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? self * 2 : self
    }
}

public extension UIFont {
    static func manropeExtraLight(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.extraLight.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeLight(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.light.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeRegular(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.regular.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeMedium(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.medium.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeSemiBold(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.semiBold.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeBold(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.bold.with(size: isError ? size : size.autoScaledForDevice) }
    static func manropeExtraBold(_ size: CGFloat, isError: Bool = false) -> UIFont { ManropeFontStyle.extraBold.with(size: isError ? size : size.autoScaledForDevice) }
}

private enum ManropeFontStyle: String {
    case extraLight = "Manrope-ExtraLight"
    case light      = "Manrope-Light"
    case regular    = "Manrope-Regular"
    case medium     = "Manrope-Medium"
    case semiBold   = "Manrope-SemiBold"
    case bold       = "Manrope-Bold"
    case extraBold  = "Manrope-ExtraBold"
    
    func with(size: CGFloat) -> UIFont {
        UIFont(name: rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
