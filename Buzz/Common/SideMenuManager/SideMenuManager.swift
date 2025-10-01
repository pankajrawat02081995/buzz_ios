//
//  SideMenuManager.swift
//  Broker Portal
//
//  Created by Pankaj on 30/04/25.
//

//import Foundation
//import UIKit
//
//// MARK: - Side Menu Controller
//class SideMenuController: UIViewController {
//    private var menuWidth: CGFloat = 280
//    private var isMenuOpen = false
//    
//    private let menuViewController: MenuViewController
//    private let mainNavigationController: UINavigationController
//    
//    private lazy var dimmingView: UIView = {
//        let view = UIView(frame: self.view.bounds)
//        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        view.alpha = 0
//        view.isHidden = true
//        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleMenuFromTap)))
//        return view
//    }()
//    
//    init(menuViewController: MenuViewController, rootViewController: UIViewController) {
//        self.menuViewController = menuViewController
//        self.mainNavigationController = UINavigationController(rootViewController: rootViewController)
//        super.init(nibName: nil, bundle: nil)
//        self.menuViewController.delegate = self
//    }
//    
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupLayout()
//    }
//    
//    @objc func toggleMenuFromTap() {
//        toggleMenu() // call the other version
//    }
//    
//    private func setupLayout() {
//        addChild(mainNavigationController)
//        view.addSubview(mainNavigationController.view)
//        mainNavigationController.didMove(toParent: self)
//        self.menuWidth = self.view.frame.width - 100
//        view.insertSubview(dimmingView, aboveSubview: mainNavigationController.view)
//        
//        addChild(menuViewController)
//        menuViewController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.bounds.height)
//        view.addSubview(menuViewController.view)
//        menuViewController.didMove(toParent: self)
//    }
//    
//    func toggleMenu(forceOpen: Bool? = nil) {
//        let shouldOpen = forceOpen ?? !isMenuOpen
//        isMenuOpen = shouldOpen
//        
//        let targetX = shouldOpen ? 0 : -menuWidth
//        dimmingView.isHidden = false
//        
//        UIView.animate(withDuration: 0.3, animations: {
//            self.menuViewController.view.frame.origin.x = targetX
//            self.dimmingView.alpha = shouldOpen ? 1.0 : 0.0
//        }) { _ in
//            if !shouldOpen {
//                self.dimmingView.isHidden = true
//            }
//        }
//    }
//    
//    func setRootViewController(_ vc: UIViewController) {
//        mainNavigationController.pushViewController(vc, animated: true)// setViewControllers([vc], animated: false)
//        toggleMenu(forceOpen: false)
//    }
//    
//    func currentNavigationController() -> UINavigationController {
//        return mainNavigationController
//    }
//}
//
//extension SideMenuController: MenuViewControllerDelegate {
//    func didSelect(menuItem: SideMenuItemType) {
//        switch menuItem {
//        case .general:
//            break
//        case .professional:
//            break
//        case .trucking:
//            break
//        case .other:
//            break
//        }
//    }
//}
//
//// MARK: - Side Menu Manager (Singleton)
//class SideMenuManager {
//    static let shared = SideMenuManager()
//    private(set) var sideMenuController: SideMenuController?
//    
//    private init() {}
//    
//    func setup(menu: MenuViewController, root: UIViewController, in window: UIWindow) {
//        let controller = SideMenuController(menuViewController: menu, rootViewController: root)
//        self.sideMenuController = controller
//        window.rootViewController = controller
//        window.makeKeyAndVisible()
//    }
//    
//    func toggleMenu() {
//        sideMenuController?.toggleMenu()
//    }
//    
//    func setRootViewController(_ vc: UIViewController) {
//        sideMenuController?.setRootViewController(vc)
//    }
//    
//    func currentNavigationController() -> UINavigationController? {
//        return sideMenuController?.currentNavigationController()
//    }
//}
