//
//  HighlightTextView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 21/09/25.
//

import UIKit

final class HighlightTextView: UITextView {
    
    private let highlightColor = UIColor(red: 0/255, green: 136/255, blue: 255/255, alpha: 1) // #0088FF
    
    // Regex patterns
    private lazy var regexes: [NSRegularExpression] = {
        let patterns = [
            "#[A-Za-z0-9_]+",          // hashtags
            "@[A-Za-z0-9_]+",          // mentions
            "https?://[A-Za-z0-9./]+"  // URLs
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: []) }
    }()
    
    private let processingQueue = DispatchQueue(label: "highlightTextView.processing", qos: .userInitiated)
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        delegate = self
        isEditable = false
        isSelectable = true   // links & highlights clickable
        isScrollEnabled = false
        dataDetectorTypes = []
        font = .manropeMedium(12)
        textColor = .label
    }
    
    /// Public method to set text with highlighting
    func setHighlightedText(_ text: String,alignment: NSTextAlignment = .left,textColor:UIColor = .textBlack) {
        applyHighlighting(to: text,alignment: alignment,textColor:textColor)
    }
    
    private func applyHighlighting(to text: String,
                                   alignment: NSTextAlignment = .left,textColor:UIColor = .textBlack) {
        processingQueue.async { [weak self] in
            guard let self else { return }
            
            let attributed = NSMutableAttributedString(string: text)
            
            // Paragraph style with alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            
            // Default color + alignment
            attributed.addAttributes([
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: attributed.length))
            
            // Apply regex highlights
            for regex in self.regexes {
                let matches = regex.matches(in: text,
                                            options: [],
                                            range: NSRange(location: 0, length: text.utf16.count))
                for match in matches {
                    attributed.addAttribute(.foregroundColor,
                                            value: self.highlightColor,
                                            range: match.range)
                    
                    // Detect links
                    if regex.pattern.contains("http"),
                       let range = Range(match.range, in: text) {
                        attributed.addAttribute(.link,
                                                value: String(text[range]),
                                                range: match.range)
                    }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.attributedText = attributed
            }
        }
    }

}

// MARK: - UITextViewDelegate
extension HighlightTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        applyHighlighting(to: textView.text)
    }
    
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        print("Tapped URL:", URL.absoluteString)
        return true
    }
}
