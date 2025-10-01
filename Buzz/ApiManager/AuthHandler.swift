//
//  AuthHandler.swift
//  Broker Portal
//
//  Created by Pankaj on 28/04/25.
//

import UIKit

final class AuthHandler {
    
    static let shared = AuthHandler()
    
    private init() {}
    
    func handleUnauthorized() {
//        DispatchQueue.main.async {
//            // Safely get the key window from active scenes
//            guard let windowScene = UIApplication.shared.connectedScenes
//                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
//                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
//                return
//            }
//            
//            // Clear user session asynchronously
//            Task {
//                await UserDefaultsManager.shared.clearAll()
//            }
//            
//            // Initialize Login screen
//            let loginVC: LoginVC = LoginVC.instantiate(fromStoryboard: .main,identifier: .LoginVC)
//            let navigationController = UINavigationController(rootViewController: loginVC)
//            navigationController.modalPresentationStyle = .fullScreen
//            
//            // Set Login screen as root
//            window.rootViewController = navigationController
//            window.makeKeyAndVisible()
//        }
    }
}
