//
//  Loader.swift
//  Broker Portal
//
//  Created by Pankaj on 23/04/25.
//

import UIKit

class LoaderManager {
    
    private weak var loaderView: UIView?
    private weak var activityIndicator: UIActivityIndicatorView?
    private var timeoutTask: Task<Void, Never>?
    private var isLoaderVisible = false
    
    init() {}
    
    func showLoadingWithDelay() {
        // Cancel previous task if any
        timeoutTask?.cancel()
        
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 0 * 1_000_000_000) // adjust delay
                
                // Check if task is cancelled after sleeping
                try Task.checkCancellation()
                
                // Hide keyboard on main thread\
                Task{
                    await MainActor.run {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
                
                // Show loader on main thread
                await self?.showLoader()
                
            } catch {
                // Task was cancelled, no loader will be shown
            }
        }
    }


    
    @MainActor
    private func showLoader() {
        guard !isLoaderVisible else { return }
        isLoaderVisible = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let loaderBackgroundView = UIView(frame: window.bounds)
        loaderBackgroundView.backgroundColor = UIColor.clear // Start transparent
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loaderBackgroundView.center
        activityIndicator.alpha = 0
        loaderBackgroundView.addSubview(activityIndicator)
        
        window.addSubview(loaderBackgroundView)
        
        // Animate the background fade and indicator appearance
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            loaderBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            activityIndicator.alpha = 1
        } completion: { _ in
            activityIndicator.startAnimating()
        }
        
        self.loaderView = loaderBackgroundView
        self.activityIndicator = activityIndicator
    }
    
    @MainActor
    func hideLoading() {
        timeoutTask?.cancel()
        timeoutTask = nil
        
        guard let loaderView = self.loaderView,
              let activityIndicator = self.activityIndicator else {
            return
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
            loaderView.alpha = 0
            activityIndicator.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            activityIndicator.stopAnimating()
            loaderView.removeFromSuperview()
            self.loaderView = nil
            self.activityIndicator = nil
            self.isLoaderVisible = false
        }
    }
    
}
