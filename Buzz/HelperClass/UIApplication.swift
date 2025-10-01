//
//  UIApplication.swift
//  Broker Portal
//
//  Created by Pankaj on 06/05/25.
//

import UIKit

extension UIApplication {
    static func topNavigationController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UINavigationController? {
        
        if let nav = base as? UINavigationController {
            return nav.visibleViewController?.navigationController ?? nav
        } else if let tab = base as? UITabBarController,
                  let selected = tab.selectedViewController {
            return topNavigationController(base: selected)
        } else if let presented = base?.presentedViewController {
            return topNavigationController(base: presented)
        }
        return base?.navigationController
    }
}
