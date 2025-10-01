//
//  CustomMarkerView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 14/08/25.
//

//import Foundation
//
//class CustomMarkerView: UIView {
//    
//    @IBOutlet weak var userImageView: UIImageView!
//    @IBOutlet weak var ratingLabel: UILabel!
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupView()
//    }
//    
//    private func setupView() {
//        userImageView.layer.cornerRadius = userImageView.frame.width / 2
//        userImageView.clipsToBounds = true
//        ratingLabel.textColor = .orange
//        ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
//    }
//    
//    func configure(image: UIImage, rating: Double) {
//        userImageView.image = image
//        ratingLabel.text = String(format: "%.1f", rating)
//    }
//}
import UIKit

final class CustomMarkerView: UIView {
    
    private let imageView = UIImageView()
    private let ratingView = UIView()
    private let ratingLabel = UILabel()
    private let starImage = UIImageView()
    
    init(frame: CGRect, profileImage: UIImage?, rating: String) {
        super.init(frame: frame)
        setupUI(profileImage: profileImage, rating: rating)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI(profileImage: UIImage?, rating: String) {
        // Pin background (you can also use your own pin PNG here)
        self.backgroundColor = .clear
        
        // Profile Image Circle
        imageView.image = profileImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Rating container
        ratingView.backgroundColor = .white
        ratingView.layer.cornerRadius = 8
        ratingView.layer.borderWidth = 1
        ratingView.layer.borderColor = UIColor.lightGray.cgColor
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ratingView)
        
        // Star Icon
        starImage.image = UIImage(systemName: "star.fill")
        starImage.tintColor = .orange
        starImage.translatesAutoresizingMaskIntoConstraints = false
        ratingView.addSubview(starImage)
        
        // Rating Label
        ratingLabel.text = rating
        ratingLabel.font = .boldSystemFont(ofSize: 14)
        ratingLabel.textColor = .darkGray
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingView.addSubview(ratingLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            ratingView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            ratingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ratingView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            ratingView.heightAnchor.constraint(equalToConstant: 24),
            ratingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            starImage.leadingAnchor.constraint(equalTo: ratingView.leadingAnchor, constant: 6),
            starImage.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor),
            starImage.widthAnchor.constraint(equalToConstant: 16),
            starImage.heightAnchor.constraint(equalToConstant: 16),
            
            ratingLabel.leadingAnchor.constraint(equalTo: starImage.trailingAnchor, constant: 4),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingView.trailingAnchor, constant: -6),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor)
        ])
    }
    
    /// Convert UIView → UIImage
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            layer.render(in: ctx.cgContext)
        }
    }
}
