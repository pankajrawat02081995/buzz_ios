//
//  UIView.swift
//  Broker Portal
//
//  Created by Pankaj on 17/06/25.
//

import UIKit
import ObjectiveC

extension UIView {
    func showPopTip(
        message: String,
        backgroundColor: UIColor = .textWhite,
        textColor: UIColor = .AppLightGray,
        borderColor: UIColor = .AppLightGray,
        font: UIFont = .manropeSemiBold(14),
        cornerRadius: CGFloat = 8
    ) {
        let tip = PopTipView(
            message: message,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderColor: borderColor,
            font: font,
            cornerRadius: cornerRadius
        )
        tip.show(from: self)
    }
}

//MARK: - Dotted Line Code

@IBDesignable
final class DottedView: UIView {
    
    // MARK: - Inspectable Properties for Storyboard
    @IBInspectable var dottedColor: UIColor = .black
    @IBInspectable var dottedLineWidth: CGFloat = 1
    @IBInspectable var dottedCornerRadius: CGFloat = 0
    @IBInspectable var dottedDashLength: CGFloat = 4
    @IBInspectable var dottedGapLength: CGFloat = 4
    @IBInspectable var dottedPosition: String = "border" // "border", "top", "bottom", "left", "right"
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawDotted()
    }
    
    private func drawDotted() {
        layer.sublayers?.removeAll(where: { $0.name == "DottedLineLayer" })
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "DottedLineLayer"
        shapeLayer.strokeColor = dottedColor.cgColor
        shapeLayer.lineWidth = dottedLineWidth
        shapeLayer.lineDashPattern = [dottedDashLength as NSNumber, dottedGapLength as NSNumber]
        shapeLayer.fillColor = nil
        
        let path = UIBezierPath()
        
        switch dottedPosition.lowercased() {
        case "top":
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: bounds.width, y: 0))
            
        case "bottom":
            path.move(to: CGPoint(x: 0, y: bounds.height))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            
        case "left":
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: bounds.height))
            
        case "right":
            path.move(to: CGPoint(x: bounds.width, y: 0))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            
        default: // border
            shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: dottedCornerRadius).cgPath
        }
        
        if dottedPosition.lowercased() != "border" {
            shapeLayer.path = path.cgPath
        }
        
        shapeLayer.frame = bounds
        layer.addSublayer(shapeLayer)
    }
}

extension UIView {

    private struct AssociatedKeys {
        static var gradientLayer = 1001
        static var passwordImages = 11
        static var passwordImageView = 111
    }

    private var storedGradientLayer: CAGradientLayer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.gradientLayer) as? CAGradientLayer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.gradientLayer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Apply a top-left to bottom-right gradient with memory safety.
    /// - Parameters:
    ///   - startColor: The starting color of the gradient.
    ///   - endColor: The ending color of the gradient.
    ///   - cornerRadius: Optional corner radius.
    func applyDiagonalGradient(startColor: UIColor = .themeOrangeStart,
                               endColor: UIColor = .themeOrangeEnd,
                               cornerRadius: CGFloat = 0) {

        // Remove old gradient safely
        storedGradientLayer?.removeFromSuperlayer()

        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = cornerRadius

        layer.insertSublayer(gradient, at: 0)
        storedGradientLayer = gradient

        // Auto-resize on layout
        setNeedsLayout()
    }

    /// Should be called inside `layoutSubviews` to resize gradient
    func updateGradientFrameIfNeeded() {
        storedGradientLayer?.frame = bounds
    }
}

extension UIView {
    func addInnerShadow(cornerRadius: CGFloat = 12,
                        color: UIColor = .black,
                        opacity: Float = 0.2,
                        radius: CGFloat = 6) {
        
        // Remove old shadows
        layer.sublayers?
            .filter { $0.name == "innerShadow" }
            .forEach { $0.removeFromSuperlayer() }
        
        layoutIfNeeded()
        
        let innerShadow = CAShapeLayer()
        innerShadow.name = "innerShadow"
        innerShadow.frame = bounds
        innerShadow.cornerRadius = cornerRadius
        
        // Outer rect (slightly bigger)
        let outerPath = UIBezierPath(roundedRect: bounds.insetBy(dx: -radius * 2,
                                                                 dy: -radius * 2),
                                     cornerRadius: cornerRadius + radius)
        
        // Inner rect (the actual view)
        let innerPath = UIBezierPath(roundedRect: bounds,
                                     cornerRadius: cornerRadius).reversing()
        
        // Combine paths → creates a "hole"
        outerPath.append(innerPath)
        
        innerShadow.path = outerPath.cgPath
        innerShadow.fillRule = .evenOdd
        
        // Shadow settings
        innerShadow.shadowColor = color.cgColor
        innerShadow.shadowOffset = .zero
        innerShadow.shadowOpacity = opacity
        innerShadow.shadowRadius = radius
        
        layer.addSublayer(innerShadow)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true   // important → clips inside only
    }
}


