//
//  UIImage.swift
//  Broker Portal
//
//  Created by Pankaj on 05/05/25.
//

import UIKit
import SDWebImageWebPCoder

struct UserImageGenerator {

    static func generateProfileImage(
        imageURLString: String?,
        firstName: String?,
        lastName: String?,
        size: CGSize = CGSize(width: 40, height: 40), // Adjusted for navigation bar use
        backgroundColor: UIColor = .lightGray,
        textColor: UIColor = .textWhite,
        font: UIFont = .manropeBold(20) // Adjusted font size
    ) async -> UIImage? {
        
        // Attempt to download the image
        if let urlString = imageURLString,
           let url = URL(string: urlString) {
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    return downloadedImage.circularImage(size: size)
                } else {
                    Log.error("Failed to convert downloaded data to UIImage")
                }
            } catch {
                Log.error("Error downloading image: \(error)")
            }
        } else {
            Log.error("Invalid URL: \(String(describing: imageURLString ?? ""))")
        }
        
        // If image not available, generate initials image
        let initials = "\(firstName?.first?.uppercased() ?? "")\(lastName?.first?.uppercased() ?? "")"
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Initials text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            initials.draw(in: rect, withAttributes: attributes)
        }.circularImage(size: size)
    }
}

extension UIImage {
    func circularImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            path.addClip()
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

private let imageCache = NSCache<NSString, UIImage>()
private var taskKey: UInt8 = 0

extension UIImageView {
    private var currentTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &taskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func setImage(
        from urlString: String,
        placeholder: UIImage? = nil,
        showLoader: Bool = true,
        isPreview: Bool = false
    ) {
        // Cancel previous task (important for table/collection cell reuse)
        currentTask?.cancel()
        self.image = placeholder
        
        // Remove old preview gestures if reused
        self.isUserInteractionEnabled = false
        self.gestureRecognizers?.forEach { self.removeGestureRecognizer($0) }
        
        // If placeholder exists and URL is empty/invalid → just show placeholder (skip loader)
        guard urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              let url = URL(string: urlString) else {
            return
        }
        
        // Add loader only if placeholder is nil
        var loader: UIActivityIndicatorView?
        if showLoader && placeholder == nil {
            loader = UIActivityIndicatorView(style: .medium)
            loader?.translatesAutoresizingMaskIntoConstraints = false
            loader?.startAnimating()
            loader?.hidesWhenStopped = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let loader = loader else { return }
                self.addSubview(loader)
                NSLayoutConstraint.activate([
                    loader.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    loader.centerYAnchor.constraint(equalTo: self.centerYAnchor)
                ])
            }
        }
        
        // Check cache
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            self.contentMode = .scaleAspectFill
            loader?.stopAnimating()
            loader?.removeFromSuperview()
            
            if isPreview { self.enablePreview(for: cachedImage) }
            return
        }
        
        // Progressive download
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            // On failure → keep placeholder, remove loader
            if error != nil || data == nil {
                DispatchQueue.main.async {
                    loader?.stopAnimating()
                    loader?.removeFromSuperview()
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: urlString as NSString)
                DispatchQueue.main.async {
                    self.image = image
                    self.contentMode = .scaleAspectFill
                    loader?.stopAnimating()
                    loader?.removeFromSuperview()
                    
                    if isPreview { self.enablePreview(for: image) }
                }
            }
        }
        task.resume()
        currentTask = task
    }
    
    // MARK: - Enable Image Preview
    private func enablePreview(for image: UIImage) {
        self.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openPreview))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func openPreview() {
        guard let image = self.image else { return }
        let previewVC = ImagePreviewController(image: image)
        previewVC.modalPresentationStyle = .fullScreen
        
        if let topVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController {
            topVC.present(previewVC, animated: true)
        }
    }
}

// MARK: - Full Screen Image Preview Controller
final class ImagePreviewController: UIViewController, UIScrollViewDelegate {
    private var image: UIImage? // weak ref after dismiss
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        view.addSubview(scrollView)
        
        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = scrollView.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            scrollView.addSubview(imageView)
        }
        
        // Close Button
        let closeButton = UIButton(type: .system)
//        closeButton.setImage(.icRedCross, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 18
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true) { [weak self] in
            // release image memory after dismiss
            self?.image = nil
        }
    }
}



extension UIImage {
    
    func toWebPData(quality: CGFloat = 0.8) -> Data? {
        // Get shared WebP coder
        let webPCoder = SDImageWebPCoder.shared
        
        // Register WebP coder once if not already registered
        if let coders = SDImageCodersManager.shared.coders{
            if !coders.contains(where: { $0 is SDImageWebPCoder }) {
                SDImageCodersManager.shared.addCoder(webPCoder)
            }
        }
        
        // Encode UIImage to WebP data
        let options: [SDImageCoderOption: Any] = [
            .encodeCompressionQuality: quality
        ]
        
        return webPCoder.encodedData(with: self, format: .webP, options: options)
    }

    
    /// Convert UIImage to Base64 string
    func toBase64(compressionQuality: CGFloat = 0.05) -> String? {
        guard let data = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        return data.base64EncodedString(options: .lineLength64Characters)
    }

    /// Create UIImage from Base64 string
    static func fromBase64(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)
    }
}
