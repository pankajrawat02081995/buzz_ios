//
//  IBDesignable.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import UIKit

@IBDesignable
public extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let cgColor = layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get {
            guard let cgColor = layer.shadowColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get { layer.shadowOpacity }
        set { layer.shadowOpacity = newValue }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get { layer.shadowOffset }
        set { layer.shadowOffset = newValue }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get { layer.shadowRadius }
        set { layer.shadowRadius = newValue }
    }
    
    /// Programmatically apply basic style
    func applyStyle(
        cornerRadius: CGFloat = 0,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0,
        shadowColor: UIColor? = nil,
        shadowOpacity: Float = 0,
        shadowOffset: CGSize = .zero,
        shadowRadius: CGFloat = 0
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowOpacity = shadowOpacity
        self.shadowOffset = shadowOffset
        self.shadowRadius = shadowRadius
    }
}

@IBDesignable
public extension UITextField {
    
    @IBInspectable var leftPadding: CGFloat {
        get {
            return leftView?.frame.width ?? 0
        }
        set {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: self.frame.height))
            leftView = paddingView
            leftViewMode = .always
        }
    }
    
    @IBInspectable var rightPadding: CGFloat {
        get {
            return rightView?.frame.width ?? 0
        }
        set {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: self.frame.height))
            rightView = paddingView
            rightViewMode = .always
        }
    }
    
    @IBInspectable var leftImage: UIImage? {
            get { return (leftView as? UIImageView)?.image }
            set {
                if let image = newValue {
                    let imageView = UIImageView(image: image)
                    imageView.contentMode = .scaleAspectFit

                    // Match textfield height dynamically
                    let padding: CGFloat = 8
                    let imageSize: CGFloat = 20
                    let height = self.frame.height

                    let containerWidth = imageSize + padding * 2
                    let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: height))

                    // Center image vertically
                    imageView.frame = CGRect(
                        x: padding,
                        y: (height - imageSize) / 2,
                        width: imageSize,
                        height: imageSize
                    )

                    container.addSubview(imageView)
                    leftView = container
                    leftViewMode = .always
                } else {
                    leftView = nil
                }
            }
        }
    
    @IBInspectable var rightImage: UIImage? {
        get { return nil }
        set {
            if let image = newValue {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                
                let containerWidth: CGFloat = 40
                let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 24))
                imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                container.addSubview(imageView)
                
                rightView = container
                rightViewMode = .always
                rightView?.isUserInteractionEnabled = false
            } else {
                rightView = nil
            }
        }
    }
    
    @IBInspectable var placeholderTextColor: UIColor? {
        get {
            return attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        }
        set {
            guard let placeholder = placeholder, let color = newValue else { return }
            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: color]
            )
        }
    }
}

@IBDesignable
public extension UITextView {
    
    // MARK: - Associated Keys
    private struct AssociatedKeys {
        static var placeholderLabel: UInt8 = 0
        static var placeholderText: UInt8 = 1
        static var placeholderColor: UInt8 = 2
    }
    
    // MARK: - Placeholder Label
    private var placeholderLabel: UILabel {
        if let label = objc_getAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderLabel)) as? UILabel {
            return label
        }
        
        let label = UILabel()
        label.numberOfLines = 0
        label.font = self.font
        label.textColor = placeholderColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        addSubview(label)
        
        objc_setAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderLabel), label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        updatePlaceholderConstraints()
        
        return label
    }
    
    // MARK: - Placeholder Text
    @IBInspectable var placeholder: String {
        get {
            return objc_getAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderText)) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderText), newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            placeholderLabel.text = newValue
            placeholderLabel.isHidden = !text.isEmpty
            
            NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
        }
    }
    
    // MARK: - Placeholder Color
    @IBInspectable var placeholderColor: UIColor {
        get {
            return objc_getAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderColor)) as? UIColor ?? .lightGray
        }
        set {
            objc_setAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderColor), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            placeholderLabel.textColor = newValue
        }
    }
    
    // MARK: - Padding (textContainerInset)
    @IBInspectable var paddingTop: CGFloat {
        get { return textContainerInset.top }
        set {
            textContainerInset.top = newValue
            updatePlaceholderConstraints()
        }
    }
    
    @IBInspectable var paddingLeft: CGFloat {
        get { return textContainerInset.left }
        set {
            textContainerInset.left = newValue
            updatePlaceholderConstraints()
        }
    }
    
    @IBInspectable var paddingBottom: CGFloat {
        get { return textContainerInset.bottom }
        set {
            textContainerInset.bottom = newValue
            updatePlaceholderConstraints()
        }
    }
    
    @IBInspectable var paddingRight: CGFloat {
        get { return textContainerInset.right }
        set {
            textContainerInset.right = newValue
            updatePlaceholderConstraints()
        }
    }
    
    // MARK: - Placeholder Visibility
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    // MARK: - Update Placeholder Constraints
    private func updatePlaceholderConstraints() {
        guard let label = objc_getAssociatedObject(self, UnsafeRawPointer(&AssociatedKeys.placeholderLabel)) as? UILabel else { return }
        
        label.removeFromSuperview()
        addSubview(label)
        
        NSLayoutConstraint.deactivate(label.constraints)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerInset.top),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textContainerInset.left + textContainer.lineFragmentPadding),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -(textContainerInset.right + textContainer.lineFragmentPadding))
        ])
    }
}

@IBDesignable
final class PasswordTextField: UITextField {
    
    private var rightImageView: UIImageView!
    
    @IBInspectable var passwordrightImage: UIImage? {
        get { return rightImageView?.image }
        set {
            if let image = newValue {
                setupRightView(with: image)
            } else {
                rightView = nil
                rightImageView = nil
            }
        }
    }
    
    private func setupRightView(with image: UIImage) {
            // Create imageView
            rightImageView = UIImageView(image: image)
            rightImageView.contentMode = .scaleAspectFit
            rightImageView.isUserInteractionEnabled = true
            rightImageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            
            // Add tap
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRightImage))
            rightImageView.addGestureRecognizer(tapGesture)
            
            // Wrap in container with extra padding
            let containerWidth: CGFloat = 24 + 16   // icon size + right padding
            let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 30))
            
            // Place imageView with 16pt padding from right
            rightImageView.frame.origin.x = containerWidth - 40
            rightImageView.center.y = container.bounds.midY
            container.addSubview(rightImageView)
            
            rightView = container
            rightViewMode = .always
        }
        
    
    @objc private func didTapRightImage() {
        // Toggle secure text entry
        isSecureTextEntry.toggle()
        
        // Change icon
        let newImage = isSecureTextEntry ? UIImage(named: "ic_eye") : UIImage(named: "ic_eye_off")
        rightImageView.image = newImage
    }
}
