////
////  KeyboardManager.swift
////  Broker Portal
////
////  Created by Pankaj on 14/05/25.
//

import UIKit

final class KeyboardManager: NSObject {
    
    static let shared = KeyboardManager()
    
    private var toolbar: UIToolbar!
    private var keyboardFrame: CGRect = .zero
    private var isKeyboardVisible = false
    
    private override init() {
        super.init()
        configureToolbar()
        registerNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Call this once from AppDelegate
    @MainActor
    func enable() {
        // Assign toolbar globally
        UITextField.appearance().inputAccessoryView = toolbar
        UITextView.appearance().inputAccessoryView = toolbar
    }
    
    // MARK: - Notifications
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Toolbar Configuration
    
    private func configureToolbar() {
        toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = .systemBlue
        toolbar.sizeToFit()
        
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        toolbar.items = [cancel, flexible, done]
    }
    
    @objc private func doneTapped() {
        UIApplication.shared.sendAction(#selector(UIView.endEditing(_:)), to: nil, from: nil, for: nil)
    }
    
    @objc private func cancelTapped() {
        UIApplication.shared.sendAction(#selector(UIView.endEditing(_:)), to:
                                            nil, from: nil, for: nil)
    }
    
    // MARK: - Keyboard Handling
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        keyboardFrame = frame
        isKeyboardVisible = true
        adjustScrollViewInsets()
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
        resetScrollViewInsets()
    }
    
    private func adjustScrollViewInsets() {
        guard let activeField = findFirstResponder(in: UIApplication.shared.activeWindow?.rootViewController?.view ?? UIView()) as? UIView,
              let scrollView = activeField.findSuperview(of: UIScrollView.self) else { return }
        
        var bottomInset = keyboardFrame.height
        if let window = UIApplication.shared.activeWindow {
            bottomInset -= window.safeAreaInsets.bottom
        }
        
        var contentInset = scrollView.contentInset
        contentInset.bottom = bottomInset + 20
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        let fieldFrame = activeField.convert(activeField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(fieldFrame, animated: true)
    }
    
    private func resetScrollViewInsets() {
        guard let activeField = findFirstResponder(in: UIApplication.shared.activeWindow?.rootViewController?.view ?? UIView()) as? UIView,
              let scrollView = activeField.findSuperview(of: UIScrollView.self) else { return }
        
        UIView.animate(withDuration: 0.3) {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
    }
    
    // MARK: - Utility Functions
    
    private func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }
}

// MARK: - UIView Helper

private extension UIView {
    func findSuperview<T: UIView>(of type: T.Type) -> T? {
        return superview as? T ?? superview?.findSuperview(of: type)
    }
}

// MARK: - UIApplication Helper (iOS 13 - iOS 18 safe)

private extension UIApplication {
    var activeWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
        } else {
            return windows.first { $0.isKeyWindow }
        }
    }
}

/// Call `KeyboardGlobalManager.shared.start()` in AppDelegate.didFinishLaunching.
final class KeyboardGlobalManager {
    static let shared = KeyboardGlobalManager()
    private var started = false

    private init() {}

    /// Start global behavior: UITextField: Return -> resign.
    /// UITextView: add Done button above keyboard to dismiss.
    func start() {
        guard !started else { return }
        started = true

        // For UITextField: when editing begins, add a `.editingDidEndOnExit` target that resigns the field.
        NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification,
                                               object: nil,
                                               queue: .main) { notification in
            guard let tf = notification.object as? UITextField else { return }

            // Avoid adding the same action multiple times
            let selName = NSStringFromSelector(#selector(UITextField.dismissKeyboardOnReturn(_:)))
            let actions = tf.actions(forTarget: tf, forControlEvent: .editingDidEndOnExit) ?? []
            guard !actions.contains(selName) else { return }

            tf.addTarget(tf, action: #selector(UITextField.dismissKeyboardOnReturn(_:)), for: .editingDidEndOnExit)

            // Optional: set return key to `.done` to make behavior consistent
            if tf.returnKeyType == .default {
                tf.returnKeyType = .done
            }
        }

        // For UITextView: when editing begins, add a toolbar with a Done button if none exists.
        NotificationCenter.default.addObserver(forName: UITextView.textDidBeginEditingNotification,
                                               object: nil,
                                               queue: .main) { notification in
            guard let tv = notification.object as? UITextView else { return }

            // If there's already an inputAccessoryView (maybe custom), don't override it.
            guard tv.inputAccessoryView == nil else { return }

            let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done = UIBarButtonItem(title: "Done", style: .done, target: tv, action: #selector(UITextView.dismissKeyboard))
            toolbar.items = [spacer, done]
            toolbar.sizeToFit()
            tv.inputAccessoryView = toolbar
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension UITextField {
    /// Called when Return / Done is pressed. Resigns the text field.
    @objc func dismissKeyboardOnReturn(_ sender: UITextField) {
        self.resignFirstResponder()
    }
}

private extension UITextView {
    /// Called by the toolbar Done button.
    @objc func dismissKeyboard() {
        self.resignFirstResponder()
    }
}
