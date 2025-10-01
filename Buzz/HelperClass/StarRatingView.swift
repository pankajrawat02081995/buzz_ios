//
//  StarRatingView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 21/08/25.
//

import Foundation
import UIKit

@IBDesignable
class StarRatingView: UIControl {
    
    // MARK: - Inspectable Properties
    @IBInspectable var maxStars: Int = 5 {
        didSet { setupStars() }
    }
    
    @IBInspectable var rating: CGFloat = 0 {
        didSet { updateStars() }
    }
    
    @IBInspectable var filledImage: UIImage? {
        didSet { updateStars() }
    }
    
    @IBInspectable var halfImage: UIImage? {
        didSet { updateStars() }
    }
    
    @IBInspectable var emptyImage: UIImage? {
        didSet { updateStars() }
    }
    
    // MARK: - Private
    private var starImageViews: [UIImageView] = []
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStars()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupStars()
        rating = 3.5 // default preview
    }
    
    // MARK: - Setup
    private func setupStars() {
        starImageViews.forEach { $0.removeFromSuperview() }
        starImageViews.removeAll()
        
        for _ in 0..<maxStars {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            iv.image = emptyImage ?? UIImage(systemName: "star")
            starImageViews.append(iv)
            addSubview(iv)
        }
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let starWidth = bounds.width / CGFloat(maxStars)
        let starHeight = bounds.height
        for (index, iv) in starImageViews.enumerated() {
            iv.frame = CGRect(x: CGFloat(index) * starWidth, y: 0, width: starWidth, height: starHeight)
        }
        updateStars()
    }
    
    private func updateStars() {
        for (index, iv) in starImageViews.enumerated() {
            let starValue = CGFloat(index + 1)
            if rating >= starValue {
                iv.image = filledImage ?? UIImage(systemName: "star.fill")
            } else if rating + 0.5 >= starValue {
                iv.image = halfImage ?? UIImage(systemName: "star.leadinghalf.filled")
            } else {
                iv.image = emptyImage ?? UIImage(systemName: "star")
            }
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let starWidth = bounds.width / CGFloat(maxStars)
        var newRating = (location.x / starWidth)
        newRating = min(CGFloat(maxStars), max(0, newRating))
        rating = (newRating * 2).rounded() / 2 // round to nearest 0.5
        sendActions(for: .valueChanged)
    }
}
