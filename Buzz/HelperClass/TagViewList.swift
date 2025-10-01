//
//  TagViewList.swift
//  Broker Portal
//
//  Created by Pankaj on 16/06/25.
//

//TagViewList

//MARK: How to use

//tagView.configuration = TagConfiguration(
//    textFont: .systemFont(ofSize: 16, weight: .medium),
//    textColor: .black,
//    selectedTextColor: .white,
//    backgroundColor: .systemGray5,
//    selectedBackgroundColor: .systemBlue,
//    showRemoveButton: true
//)
//
//tagView.setTags(["Swift", "iOS", "UIKit", "Memory Safe", "Swift 6", "Reusable", "No Pods"])
//
//tagView.onTagTapped = { tag, isSelected in
//    print("Tag \(tag) isSelected: \(isSelected)")
//}
//
//tagView.onTagRemoved = { removedTag in
//    print("Removed tag: \(removedTag)")
//}

import UIKit

// MARK: - Configuration model to make it fully reusable

struct TagConfiguration {
    var textFont: UIFont
    var textColor: UIColor
    var selectedTextColor: UIColor
    var backgroundColor: UIColor
    var selectedBackgroundColor: UIColor
    var showRemoveButton: Bool
}

// MARK: - Tag Cell

final class TagCell: UICollectionViewCell {
    
    static let reuseIdentifiers = "TagCell"
    
    private let label = UILabel()
    private let removeButton = UIButton(type: .custom)
    private let padding: CGFloat = 12
    
    private var onRemoveAction: (() -> Void)?
    
    private var trailingWithButtonConstraint: NSLayoutConstraint?
    private var trailingWithoutButtonConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        removeButton.setTitle("×", for: .normal)
        removeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        contentView.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            
            removeButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            removeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Create two trailing constraints:
        trailingWithButtonConstraint = removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        trailingWithoutButtonConstraint = label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        
        // Activate default trailing with button
        trailingWithButtonConstraint?.isActive = true
    }
    
    @objc private func removeTapped() {
        onRemoveAction?()
    }
    
    func configure(
        text: String,
        configuration: TagConfiguration,
        isSelected: Bool,
        onRemove: (() -> Void)?
    ) {
        label.text = text
        label.font = configuration.textFont
        label.textColor = isSelected ? configuration.selectedTextColor : configuration.textColor
        contentView.backgroundColor = isSelected ? configuration.selectedBackgroundColor : configuration.backgroundColor
        
        onRemoveAction = onRemove
        
        if configuration.showRemoveButton {
            removeButton.isHidden = false
            trailingWithoutButtonConstraint?.isActive = false
            trailingWithButtonConstraint?.isActive = true
        } else {
            removeButton.isHidden = true
            trailingWithButtonConstraint?.isActive = false
            trailingWithoutButtonConstraint?.isActive = true
        }
    }
}


// MARK: - Main Common Tag View

final class CommonTagListView: UIView {
    
    private var tags: [String] = []
    private var selectedIndexes: Set<Int> = []
    
    var configuration: TagConfiguration = TagConfiguration(
        textFont: .systemFont(ofSize: 14),
        textColor: .white,
        selectedTextColor: .white,
        backgroundColor: .systemBlue,
        selectedBackgroundColor: .systemGreen,
        showRemoveButton: true
    )
    
    var onTagTapped: ((String, Bool) -> Void)?
    var onTagRemoved: ((String) -> Void)?
    
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TagCell.self, forCellWithReuseIdentifier: TagCell.reuseIdentifiers)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private var collectionViewHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        addObserverForContentSize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        addObserverForContentSize()
    }
    
    private func setupView() {
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 1)
        collectionViewHeightConstraint?.isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func addObserverForContentSize() {
        collectionView.addObserver(self, forKeyPath: "contentSize", options: [.new, .old], context: nil)
    }
    
    deinit {
        collectionView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let newSize = (change?[.newKey] as? CGSize) {
                collectionViewHeightConstraint?.constant = newSize.height
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    func setTags(_ tags: [String]) {
        self.tags = tags
        selectedIndexes.removeAll()
        collectionView.reloadData()
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: collectionView.contentSize.height)
    }
}


extension CommonTagListView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.reuseIdentifiers, for: indexPath) as? TagCell else {
            return UICollectionViewCell()
        }
        
        let tag = tags[indexPath.item]
        let isSelected = selectedIndexes.contains(indexPath.item)
        
        cell.configure(
            text: tag,
            configuration: configuration,
            isSelected: isSelected
        ) { [weak self] in
            self?.handleRemove(at: indexPath)
        }
        
        return cell
    }
    
    private func handleRemove(at indexPath: IndexPath) {
        let removedTag = tags[indexPath.item]
        tags.remove(at: indexPath.item)
        selectedIndexes.remove(indexPath.item)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.collectionView.reloadData()  // reload to update all indices properly
        })
        onTagRemoved?(removedTag)
    }
    
}

extension CommonTagListView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndexes.contains(indexPath.item) {
            selectedIndexes.remove(indexPath.item)
        } else {
            selectedIndexes.insert(indexPath.item)
        }
        collectionView.reloadItems(at: [indexPath])
        onTagTapped?(tags[indexPath.item], selectedIndexes.contains(indexPath.item))
    }
}

// MARK: - Left Alignment FlowLayout

final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        return attributes
    }
}
