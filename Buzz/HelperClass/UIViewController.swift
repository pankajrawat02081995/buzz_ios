//
//  UIViewController.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

// From inside any view controller with a navigation controller

// push(ProfileViewController.self, from: .main)
//
//// With configuration
// push(SettingsViewController.self, from: .settings) { vc in
//    vc.userID = "12345"
//    vc.isDarkModeEnabled = true
//}

enum AppTitle:String{
    case Dashboard = "Dashboard"
    case Users = "Users"
    case UserDetails = "User Details"
}

enum AppIdentifire:String{
    case DashboardVC = "DashboardVC"
    case UsersVC = "UsersVC"
    case MenuViewController = "MenuViewController"
    case LoginVC = "LoginVC"
    case SettingVC = "SettingVC"
}

enum PopupMainTitle : String{
    case Logout = "Logout"
    case Delete = "Delete Account"
    case DeletePost = "Delete this post?"
    case DeleteAppointment = "Delete Appointment"
    case CancelAppointment = "Cancel Appointment"
    case DeleteImage = "Delete Image"
}

enum PopupSubTitle: String{
    case Logout = "Are you sure you want to logout?"
    case DeleteImage = "Are you sure you want to delete image?"
    case DeleteAppointment = "Are you sure you want to delete appointment?"
    case DeletePost = "You can restore this post from Reccently delelted in your activity within 30 says. After that it will be permanently deleted."
    case CancelAppointment = "Are you sure you want to cancel appointment?"
    case Delete = "Are you sure you want to delete your account? This action cannot be undone. All your data willl be permanently deleted."
}

enum PopButtonTitle:String{
    case OK = "Ok"
    case Cancel = "Cancel"
    case Yes = "Yes"
    case No = "No"
    case Done = "Done"
    case Delete = "Delete"
}

extension UIViewController {
    
    func playVideo(from urlString: String) {
            guard let url = URL(string: urlString) else {
                Log.debug("❌ Invalid video URL string: \(urlString)")
                return
            }
            
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            present(playerViewController, animated: true) {
                player.play()
            }
        }
    
    /// Render the CustomMarker XIB into a UIImage (cheaper than using iconView)
//    func imageFromMarkerXib(title: String?, image: String?, size: CGSize = CGSize(width: 50, height: 70)) -> UIImage {
//        let view = CustomMarker.fromNib()
//        view.configure(image: image, title: title)
//        view.bounds = CGRect(origin: .zero, size: size)
//        view.layoutIfNeeded()
//        
//        let renderer = UIGraphicsImageRenderer(size: size)
//        return renderer.image { ctx in
//            view.layer.render(in: ctx.cgContext)
//        }
//    }
    
    // MARK: - Bottom Sheet Helper
    
//    func presentBottomSheet(items: [Country], title: String, onSelect: @escaping (Country) -> Void) {
//        let bottomSheet = BottomSheetVC.create(countries: items,title: title, bottomSheetType: .Country, onSelect: onSelect)
//        bottomSheet.modalPresentationStyle = .overCurrentContext
//        present(bottomSheet, animated: true)
//    }
    
    // MARK: - Navigation
    
//    func navigateToNextVC() async {
//        let user = await UserDefaultsManager.shared.fatchCurentUser()
//        var destination: UIViewController
//        
//        if user?.token?.isEmpty == true || user?.token == nil {
//            destination = OnboardingVC.instantiate(from: .main)
//        } else if user?.petsCount ?? 0 == 0 {
//            destination = LetsStartVC.instantiate(from: .main)
//        } else {
//            destination = TabbarVC.instantiate(from: .tabbar)
//        }
//        
//        // Safely get current window scene
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = scene.windows.first {
//            
//            // Replace root with AppNavigationController
//            window.rootViewController = AppNavigationController(rootViewController: destination)
//            window.makeKeyAndVisible()
//        }
//    }
    
    func dictionaryFrom<T, V>(
        array: [T],
        keyPath: KeyPath<T, ConstantParam>,
        valuePath: KeyPath<T, V?>
    ) -> [String: Any] {
        var dict: [String: Any] = [:]
        for item in array {
            let key = item[keyPath: keyPath].rawValue
            if let value = item[keyPath: valuePath] {
                dict[key] = value
            }
        }
        return dict
    }
    
    func areAllRequiredValuesPresent<T, V>(
        in array: [T],
        valuePath: KeyPath<T, V?>,
        isRequiredPath: KeyPath<T, Bool?>
    ) -> Int? where V: Collection {
        for (index, item) in array.enumerated() {
            let isRequired = item[keyPath: isRequiredPath]
            
            if isRequired == true {
                let value = item[keyPath: valuePath]
                if value == nil || value?.isEmpty == true {
                    return index
                }
            }
        }
        return nil
    }
    
    func presentPopup(
        from parentVC: UIViewController,
        mainTitle: PopupMainTitle,
        subTitle: PopupSubTitle,
        btnOkTitle: PopButtonTitle,
        btnCancelTitle: PopButtonTitle,
        onOkPressed: @escaping () -> Void,
        onCancelPressed: (() -> Void)? = nil
    ) {
        let popup = PopupView(nibName: "PopupView", bundle: nil)
        popup.modalPresentationStyle = .overCurrentContext
        popup.modalTransitionStyle = .crossDissolve
        
        popup.mainTitle = mainTitle.rawValue
        popup.subTitle = subTitle.rawValue
        popup.btnOkTitle = btnOkTitle.rawValue
        popup.btnCancelTitle = btnCancelTitle.rawValue
        
        popup.onOkPressed = onOkPressed
        popup.onCancelPressed = onCancelPressed
        
        parentVC.present(popup, animated: true)
    }
    
    /// Instantiate a view controller from a storyboard.
    /// - Parameters:
    ///   - storyboardName: The name of the storyboard file.
    ///   - identifier: The view controller's storyboard ID. If nil, the class name will be used.
    /// - Returns: An instantiated view controller of the expected type.
    
    static func instantiate<T: UIViewController>(fromStoryboard storyboardName: AppStoryboard, identifier: AppIdentifire? = nil) -> T {
        let storyboard = UIStoryboard(name: storyboardName.rawValue, bundle: nil)
        let id = identifier?.rawValue ?? String(describing: T.self)
        
        guard let viewController = storyboard.instantiateViewController(withIdentifier: id) as? T else {
            Log.error("❌ ViewController with identifier \(id) not found in \(storyboardName) storyboard.")
            fatalError("❌ ViewController with identifier \(id) not found in \(storyboardName) storyboard.")
        }
        return viewController
    }
    
    /// Push a view controller from storyboard onto the current navigation stack
    public func push<T: UIViewController>(_ type: T.Type, from storyboard: AppStoryboard, setup: ((T) -> Void)? = nil) {
        let vc = T.instantiate(from: storyboard)
        setup?(vc)
        
        if let nav = UIApplication.topNavigationController() {
            nav.pushViewController(vc, animated: true)
        } else {
            guard let navigationController = self.navigationController else {
                Log.error("NavigationController not found. Make sure this view controller is embedded in a UINavigationController.")
                return
            }
            navigationController.pushViewController(vc, animated: true)
        }
    }
    
    /// Push a view controller from storyboard onto the current navigation stack
    public func set<T: UIViewController>(_ type: T.Type, from storyboard: AppStoryboard, setup: ((T) -> Void)? = nil) {
        let vc = T.instantiate(from: storyboard)
        setup?(vc)
        
        if let nav = UIApplication.topNavigationController() {
            nav.setViewControllers([vc], animated: true)
        } else {
            guard let navigationController = self.navigationController else {
                Log.error("NavigationController not found. Make sure this view controller is embedded in a UINavigationController.")
                return
            }
            navigationController.setViewControllers([vc], animated: true)
        }
    }
    
    public func popView(){
        navigationController?.popViewController(animated: true)
    }
    
    /// Present a view controller from storyboard onto the current navigation stack
    public func present<T: UIViewController>(_ type: T.Type, from storyboard: AppStoryboard, setup: ((T) -> Void)? = nil) {
        let vc = T.instantiate(from: storyboard)
        setup?(vc)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
    
}

//extension UIViewController {
//    
//    // MARK: How to use
//    //        configureNavigationBar(title: "Abc",leftImage: UIImage(named: "Vector"), leftAction:  {
//    //            debugPrint("Tap")
//    //        })
//    
//    /// Configure navigation bar with customizable left and right buttons (memory-safe)
//    ///   - Parameters:
//    ///   - title: Title to display in the navigation bar
//    ///   - leftTitle: Optional left button title
//    ///   - leftImage: Optional left button image
//    ///   - leftAction: Action closure for left button (default: pop)
//    ///   - rightTitle: Optional right button title
//    ///   - rightImage: Optional right button image
//    ///   - rightAction: Action closure for right button
//    
//    func actionSheet(agencyID: Bool) {
//        var actions: [ActionSheetAction] = [
//            .init(title: "User Profile", type: .default, handler: {
//                Log.error("User Profile tapped")
//            })
//        ]
//        
//        if agencyID {
//            actions.append(
//                .init(title: "Change Agency", type: .default, handler: {
//                    Task {
//                        self.present(SelectAgencyVC.self, from: .main) { vc in
//                            vc.saveAgency = {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
//                                    Task { @MainActor in
//                                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                                           let sceneDelegate = scene.delegate as? SceneDelegate {
//                                            await sceneDelegate.setRoot()
//                                        }
//                                    }
//                                })
//                            }
//                        }
//                    }
//                })
//            )
//        }
//        
//        actions.append(contentsOf: [
//            .init(title: "Logout", type: .destructive, handler: {
//                self.presentPopup(from: self, mainTitle: .Logout, subTitle: .Logout, btnOkTitle: .Yes, btnCancelTitle: .No) {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        Task { @MainActor in
//                            await UserDefaultsManager.shared.clearAll()
//                            
//                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                               let sceneDelegate = scene.delegate as? SceneDelegate {
//                                await sceneDelegate.setRoot()
//                            }
//                        }
//                    }
//                    
//                }
//            }),
//            .init(title: "Cancel", type: .cancel, handler: nil)
//        ])
//        
//        // Run the async title setup inside Task
//        Task {
//            let firstName = await UserDefaultsManager.shared.fatchCurentUser()?.firstName ?? ""
//            let lastName = await UserDefaultsManager.shared.fatchCurentUser()?.lastName ?? ""
//            let agencyName = await UserDefaultsManager.shared.getSelectedAgency()?.name ?? ""
//            
//            let title = agencyID ? "\(firstName) \(lastName)\n\(agencyName)" : "\(firstName) \(lastName)"
//            
//            ActionSheetHelper.showActionSheet(
//                on: self,
//                title: title,
//                message: "Please select an action",
//                actions: actions,
//                sourceView: self.view
//            )
//        }
//    }
//    
//    func configureNavigationBar(
//        title: String? = nil,
//        leftTitle: String? = nil,
//        leftImage: Icon? = nil,
//        leftCustomImage: UIImage? = nil,
//        leftAction: (() -> Void)? = nil,
//        rightTitle: String? = nil,
//        rightImage: Icon? = nil,
//        rightCustomImage: UIImage? = nil,
//        isRightCustomImage: Bool = false,
//        rightAction: (() -> Void)? = nil
//    ) {
//        self.title = title
//        
//        // MARK: - Configure Modern Navigation Bar Appearance (Swift 6)
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = .HeaderGreenColor
//        appearance.titleTextAttributes = [
//            .foregroundColor: UIColor.white,
//            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
//        ]
//        appearance.largeTitleTextAttributes = [
//            .foregroundColor: UIColor.white,
//            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
//        ]
//        
//        guard let navigationBar = navigationController?.navigationBar else { return }
//        navigationBar.standardAppearance = appearance
//        navigationBar.scrollEdgeAppearance = appearance
//        navigationBar.compactAppearance = appearance
//        navigationBar.tintColor = .white // Optional: sets bar button item color
//        
//        // MARK: - Left Bar Button Item
//        navigationItem.leftBarButtonItem = createBarButtonItem(
//            title: leftTitle,
//            image: leftImage?.image,
//            customImage: leftCustomImage,
//            action: leftAction
//        )
//        
//        // MARK: - Right Bar Button Item
////        Task {
////            let customImage: UIImage? = await {
////                if isRightCustomImage {
////                    if let image = rightCustomImage {
////                        return image
////                    } else {
////                        let user = await UserDefaultsManager.shared.fatchCurentUser()
////                        return await UserImageGenerator.generateProfileImage(
////                            imageURLString: user?.image ?? "",
////                            firstName: user?.firstName ?? "",
////                            lastName: user?.lastName ?? ""
////                        )
////                    }
////                }
////                return nil
////            }()
////            
////            navigationItem.rightBarButtonItem = createBarButtonItem(
////                title: rightTitle,
////                image: rightImage?.image,
////                customImage: customImage,
////                isRightCustomImage: isRightCustomImage,
////                action: rightAction
////            )
////        }
//    }
//    
//    private func createBarButtonItem(
//        title: String?,
//        image: UIImage?,
//        customImage: UIImage?,isRightCustomImage :Bool?=false,
//        action: (() -> Void)?
//    ) -> UIBarButtonItem? {
//        if let customImage = customImage {
//            let button = UIButton(type: .custom)
//            button.setImage(customImage, for: .normal)
//            button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//            button.imageView?.contentMode = .scaleAspectFill
//            button.layer.cornerRadius = 20
//            button.layer.borderColor = UIColor.headerGreen.cgColor
//            button.layer.borderWidth = 1
//            button.clipsToBounds = true
//            button.isUserInteractionEnabled = true
//            
//            if action != nil || isRightCustomImage == true{
//                button.addAction(UIAction { _ in
//                    //                     action()
//                    if isRightCustomImage == true{
//                        Task{
//                            let isAdmin = await UserDefaultsManager.shared.isAdmin()
//                            self.actionSheet(agencyID: isAdmin)
//                        }
//                    }else{
//                        //                        action()
//                    }
//                }, for: .touchUpInside)
//            }
//            
//            return UIBarButtonItem(customView: button)
//        } else if let image = image {
//            if let action = action {
//                return UIBarButtonItem(
//                    title: title,
//                    image: image,
//                    primaryAction: UIAction { _ in
//                        action()
//                    },
//                    menu: nil
//                )
//            } else {
//                let barButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(defaultBackAction))
//                barButton.image = image
//                return barButton
//            }
//        } else if let title = title {
//            let barButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(defaultBackAction))
//            return barButton
//        }
//        
//        return nil
//    }
//    
//    // MARK: - Default Back Button Fallback
//    
//    @objc private func defaultBackAction() {
//        navigationController?.popViewController(animated: true)
//    }
//}
