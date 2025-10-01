//
//  FlowtingButton.swift
//  Broker Portal
//
//  Created by Pankaj on 09/06/25.
//

import UIKit

//MARK: How To Use

//MARK: Create Variable
//private var floatingButton: FloatingButton?

//MARK: Impliment
//floatingButton = FloatingButton(
//            on: self,
//            image: UIImage(systemName: "phone.fill")!,
//            position: CGPoint(x: view.frame.width - 80, y: view.frame.height - 120)
//        ) { [weak self] in
//            self?.callButtonTapped()
//        }
// private func callButtonTapped() {
//        print("Call button tapped")
//        // Perform call action
//    }

final class FloatingButton {
    
    private let button = UIButton(type: .custom)
    private weak var viewController: UIViewController?
    private var action: (() -> Void)?
    
    init(
        on viewController: UIViewController,
        image: UIImage,
        position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 150),
        size: CGFloat = 56,
        backgroundColor: UIColor = .clear,
        tintColor: UIColor = .white,
        action: @escaping () -> Void
    ) {
        self.viewController = viewController
        
        // Prevent closure retain cycles
        self.action = { [weak viewController] in
            guard viewController != nil else { return }
            action()
        }
        
        button.frame = CGRect(x: position.x, y: position.y, width: size, height: size)
        button.setImage(image, for: .normal)
        button.backgroundColor = backgroundColor
        button.tintColor = tintColor
        button.layer.cornerRadius = size / 2
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        viewController.view.addSubview(button)
        viewController.view.bringSubviewToFront(button)
    }
    
    @objc private func buttonTapped() {
        action?()
    }
    
    deinit {
        button.removeTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        Log.debug("FloatingButton deinitialized ✅")
    }
}
