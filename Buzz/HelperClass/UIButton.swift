//
//  UIButton.swift
//  Zupet
//
//  Created by Pankaj Rawat on 24/08/25.
//

import UIKit
private var currentTaskKey: UInt8 = 0
private let imageCache = NSCache<NSString, UIImage>()
extension UIButton {
    private var currentTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &currentTaskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &currentTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setImage(
        from urlString: String,
        placeholder: UIImage? = nil,
        showLoader: Bool = true,
        for state: UIControl.State = .normal
    ) {
        // Cancel previous task (important for cell reuse)
        currentTask?.cancel()
        self.setImage(placeholder, for: state)
        
        // Add loader if required
        var loader: UIActivityIndicatorView?
        if showLoader {
            loader = UIActivityIndicatorView(style: .medium)
            loader?.center = CGPoint(x: bounds.midX, y: bounds.midY)
            loader?.startAnimating()
            loader?.hidesWhenStopped = true
            DispatchQueue.main.async { [weak self] in
                if let loader = loader {
                    self?.addSubview(loader)
                }
            }
        }
        
        // Check cache
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.setImage(cachedImage, for: state)
            loader?.stopAnimating()
            loader?.removeFromSuperview()
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        // Progressive download
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async {
                    loader?.stopAnimating()
                    loader?.removeFromSuperview()
                }
                return
            }
            
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: urlString as NSString)
                DispatchQueue.main.async {
                    self.setImage(image, for: state)
                    loader?.stopAnimating()
                    loader?.removeFromSuperview()
                }
            }
        }
        task.resume()
        currentTask = task
    }
}
