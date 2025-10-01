//
//  UILable.swift
//  Zupet
//
//  Created by Pankaj Rawat on 22/07/25.
//

import UIKit

extension UILabel {

    /// Adds tappable highlight to specific substring(s) within the label text.
    /// - Parameters:
    ///   - substring: The text you want to highlight and make clickable.
    ///   - color: The highlight color for the substring.
    ///   - font: Optional font override for highlighted text.
    ///   - onTap: Closure called when the substring is tapped.
    func addTappableHighlight(
        substring: String,
        color: UIColor = .systemBlue,
        font: UIFont? = nil,
        onTap: @escaping () -> Void
    ) {
        guard let fullText = text, !substring.isEmpty else { return }

        isUserInteractionEnabled = true
        let attributed = NSMutableAttributedString(string: fullText)

        if let range = fullText.range(of: substring) {
            let nsRange = NSRange(range, in: fullText)
            attributed.addAttribute(.foregroundColor, value: color, range: nsRange)
            if let font = font {
                attributed.addAttribute(.font, value: font, range: nsRange)
            }

            let tapGesture = TappableTextGesture(targetRange: nsRange, action: onTap)
            addGestureRecognizer(tapGesture)
        }

        attributedText = attributed
    }
}

final class TappableTextGesture: UITapGestureRecognizer {

    private let targetRange: NSRange
    private let action: () -> Void

    init(targetRange: NSRange, action: @escaping () -> Void) {
        self.targetRange = targetRange
        self.action = action
        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(handleTap(_:)))
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let _ = label.attributedText?.string,
              let _ = label.font else { return }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString())

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        let location = gesture.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textOffset = CGPoint(
            x: (label.bounds.width - textBoundingBox.size.width) / 2 - textBoundingBox.origin.x,
            y: (label.bounds.height - textBoundingBox.size.height) / 2 - textBoundingBox.origin.y
        )

        let touchedPoint = CGPoint(x: location.x - textOffset.x, y: location.y - textOffset.y)
        let index = layoutManager.characterIndex(for: touchedPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if NSLocationInRange(index, targetRange) {
            action()
        }
    }
}
