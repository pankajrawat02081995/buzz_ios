//
//  UITableView.swift
//  Broker Portal
//
//  Created by Pankaj on 28/04/25.
//

import UIKit

extension UITableViewCell{
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }
}

extension UITableView {
    
    /// Adds a pull-to-refresh control to the table view
    func addRefreshControl(action: @escaping () -> Void) {
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(for: .valueChanged, action)
        self.refreshControl = refreshControl
    }
    
    /// Ends refreshing animation if refreshing
    func endRefreshing() {
        DispatchQueue.main.async { [weak self] in
            if self?.refreshControl?.isRefreshing == true {
                self?.refreshControl?.endRefreshing()
            }
        }
    }
    
    /// Reloads table view data on the main thread safely
    func refresh() {
        DispatchQueue.main.async { [weak self] in
            self?.reloadData()
        }
    }
    
    /// Registers a UITableViewCell using its class name automatically
    func register(cellType: UITableViewCell.Type) {
        let className = String(describing: cellType)
        self.register(UINib(nibName: className, bundle: nil), forCellReuseIdentifier: className)
    }
    
    /// Dequeues a reusable UITableViewCell in a type-safe way
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        let className = String(describing: T.self)
        guard let cell = dequeueReusableCell(withIdentifier: className, for: indexPath) as? T else {
            fatalError("Error: Could not dequeue cell with identifier: \(className)")
        }
        return cell
    }
}


// MARK: - UIControl Helper
private extension UIControl {
    
    /// Adds an action closure to UIControl (for UIRefreshControl)
    func addAction(for event: UIControl.Event, _ closure: @escaping () -> Void) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: event)
        objc_setAssociatedObject(self, UUID().uuidString, sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

/// Helper class to wrap closures for UIControl
private class ClosureSleeve {
    let closure: () -> Void
    
    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }
    
    @objc func invoke() {
        closure()
    }
}

import UIKit

extension UITableView {

    /// Sets a custom message when there's no data.
    /// - Parameters:
    ///   - message: Message to display
    ///   - font: Custom font (default is medium system font, 16pt)
    ///   - textColor: Text color (default is light gray)
    func setEmptyMessage(_ message: String,_ count: Int) {
        if count != 0{
            restoreBackground()
            return
        }
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .manropeMedium(16)
        messageLabel.textColor = .lightGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let containerView = UIView()
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -80),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])

        self.backgroundView = containerView
        self.separatorStyle = .none
    }

    /// Restores the table view to normal background.
    func restoreBackground() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

extension UITableView {
    func setEmptyView(title: String,
                      subtitle: String? = nil,
                      image: UIImage? = nil) {
        let emptyView = NoDataXIB.loadFromNib()
        emptyView.configure(title: title, subtitle: subtitle, image: image)
        // make it resize with table bounds
        emptyView.frame = bounds
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView = emptyView
    }

    func restore() {
        backgroundView = nil
    }
}
