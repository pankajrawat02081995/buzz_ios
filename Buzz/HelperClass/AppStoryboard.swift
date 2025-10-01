//
//  AppStoryboard.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import Foundation
import UIKit

public enum AppStoryboard: String {
    case main = "Main"
    case auth = "Auth"
    case tabbar = "Tabbar"
    case home = "Home"
    case vet = "Vet"
    case profile = "Profile"
    case alarm = "Alarm"
    case community = "Community"
    
    var instance: UIStoryboard {
        UIStoryboard(name: self.rawValue, bundle: .main)
    }
}

public extension UIViewController {
    
    /// Instantiate view controller from storyboard using its class name
    static func instantiate(from storyboard: AppStoryboard) -> Self {
        func instantiateVC<T: UIViewController>() -> T {
            let identifier = String(describing: self)
            return storyboard.instance.instantiateViewController(withIdentifier: identifier) as! T
        }
        return instantiateVC()
    }
}
