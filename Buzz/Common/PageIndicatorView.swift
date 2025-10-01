//
//  PageIndicatorView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 22/07/25.
//

import UIKit

final class PageIndicatorView: UIView {

    // MARK: - Public Properties

    var numberOfPages: Int = 0 {
        didSet { configureDots() }
    }

    var currentPage: Int = 0 {
        didSet { updateDots() }
    }

    // MARK: - Private Properties

    private var dotViews: [UIView] = []
    private let stackView = UIStackView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }

    // MARK: - Setup

    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func configureDots() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        for _ in 0..<numberOfPages {
            let dot = createDot()
            stackView.addArrangedSubview(dot)
            dotViews.append(dot)
        }

        updateDots()
    }

    private func updateDots() {
        for (index, dot) in dotViews.enumerated() {
            if index == currentPage {
                dot.backgroundColor = .black
                dot.layer.borderColor = UIColor.clear.cgColor
            } else {
                dot.backgroundColor = .clear
                dot.layer.borderColor = UIColor.black.cgColor
            }
        }
    }

    private func createDot() -> UIView {
        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 16).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
        dot.layer.cornerRadius = 3
        dot.layer.borderWidth = 1.4
        dot.layer.borderColor = UIColor.textBlack.cgColor
        return dot
    }
}

