//
//  UICollectionView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 22/07/25.
//

import UIKit

extension UICollectionViewCell{
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }
}

extension UICollectionView{
    /// Registers a UICollectionViewCell using its class name automatically
    func register(cellType: UICollectionViewCell.Type) {
        let className = String(describing: cellType)
        self.register(UINib(nibName: className, bundle: nil), forCellWithReuseIdentifier: className)
    }
    
    /// Dequeues a reusable UITableViewCell in a type-safe way
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        let className = String(describing: T.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: className, for: indexPath) as? T else {
            fatalError("Error: Could not dequeue cell with identifier: \(className)")
        }
        return cell
    }
}


extension UICollectionView {
    func setEmptyView(title: String,
                      subtitle: String? = nil,
                      image: UIImage? = nil) {
        let emptyView = NoDataXIB.loadFromNib()
        emptyView.configure(title: title, subtitle: subtitle, image: image)
        emptyView.frame = bounds
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView = emptyView
    }

    func restore() {
        backgroundView = nil
    }
}
