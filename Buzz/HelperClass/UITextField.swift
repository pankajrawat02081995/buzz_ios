//
//  UITextField.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import UIKit
import ObjectiveC

private var errorLabelKey: UInt8 = 0
private var prefixKey: UInt8 = 0


public extension UITextField {
    var prefixText: String? {
        get { objc_getAssociatedObject(self, &prefixKey) as? String }
        set { objc_setAssociatedObject(self, &prefixKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private func getAssociated<T>(_ key: UnsafeRawPointer) -> T? {
        objc_getAssociatedObject(self, key) as? T
    }

    private func setAssociated<T>(_ key: UnsafeRawPointer, value: T?) {
        objc_setAssociatedObject(self, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    
    func setPrefix(_ text: String) {
        self.prefixText = text   // store prefix
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14) // replace with .manropeLight(14) if custom font
        label.textColor = .black
        label.sizeToFit()
        
        // Container with padding
        let container = UIView(frame: CGRect(x: 0, y: 0,
                                             width: 74 + label.frame.width,
                                             height: label.frame.height))
        label.frame.origin.x = 62
        container.addSubview(label)
        
        self.leftView = container
        self.leftViewMode = .always
    }
    
    
    func trim() -> String{
        return self.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    func showError(message: String,
                   font: UIFont = .manropeRegular(12, isError: true),
                   textColor: UIColor = .red,
                   borderColor: UIColor = .red) {
        
        removeError() // Clean up previous label if any
        
        // Border styling
        layer.borderWidth = 1
        layer.cornerRadius = 6
        layer.borderColor = borderColor.cgColor
        
        // Create error label
        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.font = font
        errorLabel.textColor = textColor
        errorLabel.numberOfLines = 0
        
        // Add to superview
        guard let superview = self.superview else { return }
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            errorLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4)
        ])
        
        // Save reference using associated object
        objc_setAssociatedObject(self, &errorLabelKey, errorLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Shake animation
        shake()
    }
    
    func removeError() {
        if let containerView = objc_getAssociatedObject(self, &errorLabelKey) as? UIView {
            containerView.removeFromSuperview()
            objc_setAssociatedObject(self, &errorLabelKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Reset to system-default look
        layer.borderWidth = 0
        layer.borderColor = nil
    }
    
    private func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, -2, 2, 0]
        layer.add(animation, forKey: "shake")
    }
}

final class PhoneTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText)
        else {
            return false
        }
        
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        let digits = updatedText.filter(\.isNumber)
        let formatted = Validator.format(digits)
        
        textField.text = formatted
        
        // Move cursor to end (optional)
        let endPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        
        return false // prevent default system behavior
    }
}

//MARK: This Code use for disable Past Functionality

final class PasteBlocker {
    static func disablePasteGlobally() {
        UITextField.swizzleCanPerformAction()
        UITextView.swizzleCanPerformAction()
    }
}

extension UITextField {
    static func swizzleCanPerformAction() {
        guard let original = class_getInstanceMethod(self, #selector(canPerformAction(_:withSender:))),
              let swizzled = class_getInstanceMethod(self, #selector(swizzled_canPerformAction(_:withSender:))) else { return }
        method_exchangeImplementations(original, swizzled)
    }
    
    @objc func swizzled_canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(copy(_:)) || action == #selector(cut(_:)) || action == #selector(select(_:)) || action == #selector(selectAll(_:)) {
            return false
        }
        return swizzled_canPerformAction(action, withSender: sender)
    }
}

extension UITextView {
    static func swizzleCanPerformAction() {
        guard let original = class_getInstanceMethod(self, #selector(canPerformAction(_:withSender:))),
              let swizzled = class_getInstanceMethod(self, #selector(swizzled_canPerformAction(_:withSender:))) else { return }
        method_exchangeImplementations(original, swizzled)
    }
    
    @objc func swizzled_canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(copy(_:)) || action == #selector(cut(_:)) || action == #selector(select(_:)) || action == #selector(selectAll(_:)) {
            return false
        }
        return swizzled_canPerformAction(action, withSender: sender)
    }
}
