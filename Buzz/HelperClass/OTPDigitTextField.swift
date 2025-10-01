//
//  OTPDigitTextField.swift
//  Zupet
//
//  Created by Pankaj Rawat on 22/07/25.
//

import UIKit

// MARK: - OTP Configuration

struct OTPViewConfiguration {
    var digitCount: Int = 6
    var spacing: CGFloat = 10
    var font: UIFont = .manropeRegular(16)
    var textColor: UIColor = .textBlack
    var placeholderText: String = "_"
    var placeholderYOffset: CGFloat = 6
    var backgroundColor: UIColor = .AppLightGray
    var borderActiveColor: UIColor = .appGray
    var borderInactiveColor: UIColor = .clear
    var cornerRadius: CGFloat = 10
    var borderWidth: CGFloat = 1
    var fieldSize: CGFloat = 40
}

// MARK: - Delegate

protocol OTPViewDelegate: AnyObject {
    func otpDidChange(code: String)
    func otpDidComplete(isComplete: Bool)
}

// MARK: - OTP View

final class OTPView: UIStackView {

    // MARK: - OTP TextField

    final class OTPDigitTextField: UITextField {

        private let config: OTPViewConfiguration

        init(config: OTPViewConfiguration) {
            self.config = config
            super.init(frame: .zero)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            backgroundColor = config.backgroundColor
            textAlignment = .center
            font = config.font
            textColor = config.textColor
            tintColor = .clear
            keyboardType = .numberPad
            autocorrectionType = .no
            spellCheckingType = .no
            layer.cornerRadius = config.cornerRadius
            layer.borderWidth = config.borderWidth
            layer.borderColor = config.borderInactiveColor.cgColor
            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: config.fieldSize),
                heightAnchor.constraint(equalToConstant: config.fieldSize)
            ])
            updatePlaceholder()
        }

        func updatePlaceholder() {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            style.minimumLineHeight = config.font.lineHeight
            style.maximumLineHeight = config.font.lineHeight + config.placeholderYOffset

            attributedPlaceholder = NSAttributedString(
                string: config.placeholderText,
                attributes: [
                    .foregroundColor: config.textColor,
                    .font: config.font,
                    .paragraphStyle: style
                ]
            )
        }

        func updateBorder(isActive: Bool) {
            layer.borderColor = (isActive ? config.borderActiveColor : config.borderInactiveColor).cgColor
        }

        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            updateBorder(isActive: true)
            return result
        }

        override func resignFirstResponder() -> Bool {
            let result = super.resignFirstResponder()
            updateBorder(isActive: !(text?.isEmpty ?? true))
            return result
        }
    }

    // MARK: - Properties

    weak var delegate: OTPViewDelegate?
    private var config: OTPViewConfiguration
    private var textFields: [OTPDigitTextField] = []

    // MARK: - Init

    init(config: OTPViewConfiguration = OTPViewConfiguration()) {
        self.config = config
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        self.config = OTPViewConfiguration()
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        axis = .horizontal
        alignment = .fill
        distribution = .fillEqually
        spacing = config.spacing

        for i in 0..<config.digitCount {
            let field = OTPDigitTextField(config: config)
            field.tag = i
            field.delegate = self
            field.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
            textFields.append(field)
            addArrangedSubview(field)
        }

//        _ = textFields.first?.becomeFirstResponder()
    }

    // MARK: - Logic

    @objc private func textDidChange(_ sender: UITextField) {
        guard let text = sender.text, !text.isEmpty else { return }

        sender.text = String(text.prefix(1))

        if sender.tag < config.digitCount - 1 {
            _ = textFields[sender.tag + 1].becomeFirstResponder()
        } else {
            _ = sender.resignFirstResponder()
        }

        let code = getOTP()
        delegate?.otpDidChange(code: code)

        if code.count == config.digitCount {
            delegate?.otpDidComplete(isComplete: true)
        }else{
            delegate?.otpDidComplete(isComplete: false)
        }
    }

    func getOTP() -> String {
        return textFields.compactMap { $0.text }.joined()
    }

    func clear() {
        textFields.forEach {
            $0.text = nil
            $0.updateBorder(isActive: false)
            $0.updatePlaceholder()
        }
        _ = textFields.first?.becomeFirstResponder()
    }

    func setConfig(_ newConfig: OTPViewConfiguration) {
        config = newConfig
        textFields.forEach { $0.removeFromSuperview() }
        textFields.removeAll()
        setup()
    }
}

// MARK: - UITextFieldDelegate

extension OTPView: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentField = textField as? OTPDigitTextField else { return false }

        if string.isEmpty {
            currentField.text = ""
            currentField.updateBorder(isActive: true)
            if currentField.tag > 0 {
                _ = textFields[currentField.tag - 1].becomeFirstResponder()
            }
            delegate?.otpDidChange(code: getOTP())
            if getOTP().count == config.digitCount {
                delegate?.otpDidComplete(isComplete: true)
            }else{
                delegate?.otpDidComplete(isComplete: false)
            }
            return false
        }

        return true
    }
}
