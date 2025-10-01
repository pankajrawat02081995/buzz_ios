//
//  ToastManager.swift
//  Broker Portal
//
//  Created by Pankaj on 23/04/25.
//

import UIKit

actor ToastManager {
    
    static let shared = ToastManager()
    
    private var isShowing = false
    
    func showToast(
        message: String?,
        duration: TimeInterval = 2.0,
        font: UIFont = .manropeBold(18),
        backgroundColor: UIColor = UIColor.textBlack,
        textColor: UIColor = .textWhite
    ) async {
        // Ensure only one toast at a time
        if isShowing { return }
        isShowing = true
        
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                Task { await self.dismissed() }
                return
            }
            
            let toastLabel = PaddingLabel()
            toastLabel.text = message ?? ErrorMessages.somethingWentWrong.rawValue
            toastLabel.font = font
            toastLabel.textColor = textColor
            toastLabel.backgroundColor = backgroundColor
            toastLabel.textAlignment = .center
            toastLabel.alpha = 0.0
            toastLabel.numberOfLines = 0
            toastLabel.layer.cornerRadius = 8
            toastLabel.clipsToBounds = true
            toastLabel.translatesAutoresizingMaskIntoConstraints = false
            
            window.addSubview(toastLabel)
            
            // Constraints: top with padding, horizontal margin 20, height adjusts with content
            NSLayoutConstraint.activate([
                toastLabel.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 16),
                toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 20),
                toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -20),
                toastLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor)
            ])
            
            toastLabel.layoutIfNeeded()
            
            // Animate in and out
            UIView.animate(withDuration: 0.3, animations: {
                toastLabel.alpha = 1.0
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    UIView.animate(withDuration: 0.3, animations: {
                        toastLabel.alpha = 0.0
                    }) { _ in
                        toastLabel.removeFromSuperview()
                        Task { await self.dismissed() }
                    }
                }
            }
        }
    }
    
    private func dismissed() {
        isShowing = false
    }
}

class PaddingLabel: UILabel {
    var padding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
    
    override func drawText(in rect: CGRect) {
        let paddedRect = rect.inset(by: padding)
        super.drawText(in: paddedRect)
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let width = size.width + padding.left + padding.right
        let height = size.height + padding.top + padding.bottom
        return CGSize(width: width, height: height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let newSize = super.sizeThatFits(size)
        return CGSize(width: newSize.width + padding.left + padding.right,
                      height: newSize.height + padding.top + padding.bottom)
    }
}
