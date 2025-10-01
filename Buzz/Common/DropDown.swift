//
//  DropDown.swift
//  Broker Portal
//
//  Created by Pankaj on 02/05/25.
//

import UIKit

final class DropdownView: UIView {
    
    private let tableView = UITableView()
    private var items: [String] = []
    private var selectionHandler: ((String) -> Void)?
    private weak var anchorView: UIView?
    
    private var backgroundTapView: UIView?
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6
        clipsToBounds = false
        
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DropdownCell")
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    func show(from view: UIView, data: [String], onSelect: @escaping (String) -> Void) {
        
        // Add a small delay to ensure keyboard has time to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = view.window else { return }
            
            self.items = data
            self.selectionHandler = onSelect
            self.anchorView = view
            
            if self.superview != nil {
                self.removeFromSuperview()
                self.backgroundTapView?.removeFromSuperview()
            }
            
            // Add tap-detecting background
            let tapView = UIView(frame: window.bounds)
            tapView.backgroundColor = .clear
            window.addSubview(tapView)
            self.backgroundTapView = tapView
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss(_:)))
            tapView.addGestureRecognizer(tapGesture)
            tapGesture.cancelsTouchesInView = false
            
            tapView.addSubview(self)
            self.reloadAndPositionDropdown()
        }
    }
    
    private func reloadAndPositionDropdown() {
        guard let anchor = anchorView, let tapView = backgroundTapView else { return }
        
        let anchorFrame = anchor.convert(anchor.bounds, to: tapView)
        let dropdownHeight = min(CGFloat(items.count) * 44.0, 200)
        let padding: CGFloat = 5
        
        let spaceBelow = tapView.frame.height - anchorFrame.maxY
        let spaceAbove = anchorFrame.minY
        
        var dropdownY: CGFloat
        if spaceBelow >= dropdownHeight + padding {
            // Show below
            dropdownY = anchorFrame.maxY + padding
        } else if spaceAbove >= dropdownHeight + padding {
            // Show above
            dropdownY = anchorFrame.minY - dropdownHeight - padding
        } else {
            // Fit in smaller space
            dropdownY = anchorFrame.maxY + padding
        }
        
        frame = CGRect(x: anchorFrame.minX,
                       y: dropdownY,
                       width: anchorFrame.width,
                       height: dropdownHeight)
        
        tableView.reloadData()
    }
    
    @objc private func dismiss(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: backgroundTapView)
        if !self.frame.contains(location) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            backgroundTapView?.removeFromSuperview()
            removeFromSuperview()
        }
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension DropdownView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.font = .manropeRegular(14)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = items[indexPath.row]
        selectionHandler?(selected)
        backgroundTapView?.removeFromSuperview()
        removeFromSuperview()
    }
}
