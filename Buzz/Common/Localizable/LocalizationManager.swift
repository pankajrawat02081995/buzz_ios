import UIKit
import Combine

// MARK: - Localization Manager

final class LocalizationManager {
    static let shared = LocalizationManager()
    
    private let languageSubject = CurrentValueSubject<String, Never>("en")
    var languagePublisher: AnyPublisher<String, Never> {
        languageSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func setLanguage(_ code: String) {
        languageSubject.send(code)
    }
    
    func localizedString(for key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

// MARK: - AssociatedObject Safe Storage for Combine

private var cancellablesKey: UInt8 = 0

/// Wrapper so we can store cancellables in Objective-C runtime safely
final class CancellableBox: NSObject {
    var set = Set<AnyCancellable>()
}

/// Every UIKit element that needs Combine cancellables will adopt this
protocol CombineCancellableStore: AnyObject {}

extension CombineCancellableStore {
    var cancellables: Set<AnyCancellable> {
        get {
            if let box = objc_getAssociatedObject(self, &cancellablesKey) as? CancellableBox {
                return box.set
            } else {
                let box = CancellableBox()
                objc_setAssociatedObject(self, &cancellablesKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return box.set
            }
        }
        set {
            let box: CancellableBox
            if let existing = objc_getAssociatedObject(self, &cancellablesKey) as? CancellableBox {
                box = existing
            } else {
                box = CancellableBox()
                objc_setAssociatedObject(self, &cancellablesKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            box.set = newValue
        }
    }
}

// Conform UIKit classes
extension UIView: CombineCancellableStore {}
extension UINavigationItem: CombineCancellableStore {}
extension UIBarButtonItem: CombineCancellableStore {}

// MARK: - Helpers

extension CombineCancellableStore {
    func bindText(key: String, apply: @escaping (String) -> Void) {
        apply(LocalizationManager.shared.localizedString(for: key))
        LocalizationManager.shared.languagePublisher
            .map { _ in LocalizationManager.shared.localizedString(for: key) }
            .sink(receiveValue: apply)
            .store(in: &cancellables)
    }
}

// MARK: - UIKit Components

extension UILabel {
    func localize(_ key: String) {
        bindText(key: key) { [weak self] text in self?.text = text }
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}


extension UIButton {
    func localize(_ key: String) {
        bindText(key: key) { [weak self] text in self?.setTitle(text, for: .normal) }
    }
}

extension UITextField {
    func localize(_ key: String) {
        bindText(key: key) { [weak self] text in self?.placeholder = text }
    }
}

extension UINavigationItem {
    func localize(_ key: String) {
        bindText(key: key) { [weak self] text in self?.title = text }
    }
}

extension UIBarButtonItem {
    func localize(_ key: String) {
        bindText(key: key) { [weak self] text in self?.title = text }
    }
}
