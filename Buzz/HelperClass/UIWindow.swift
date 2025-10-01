//
//  UIWindow.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import UIKit

public extension UIWindow {
    
    /// Set root view controller from storyboard enum + class
    func setRootViewController<T: UIViewController>(_ type: T.Type, from storyboard: AppStoryboard, animated: Bool = true) {
        let viewController = T.instantiate(from: storyboard)
        let nav = UINavigationController(rootViewController: viewController)
        setRootViewController(nav, animated: animated)
    }
    
    private func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        guard animated, let snapshot = snapshotView(afterScreenUpdates: true) else {
            rootViewController = viewController
            makeKeyAndVisible()
            return
        }
        
        rootViewController = viewController
        makeKeyAndVisible()
        
        snapshot.frame = bounds
        addSubview(snapshot)
        
        UIView.animate(withDuration: 0.4, animations: {
            snapshot.alpha = 0
        }, completion: { _ in
            snapshot.removeFromSuperview()
        })
    }
}
