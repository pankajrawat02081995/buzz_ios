//
//  PopTip.swift
//  Broker Portal
//
//  Created by Pankaj on 17/06/25.
//

import UIKit

final class PopTipView: UIView {
    
    private let label = UILabel()
    private let arrowSize: CGFloat = 10
    private weak var sourceView: UIView?
    private var dismissTimer: Timer?
    private var tapOutsideRecognizer: UITapGestureRecognizer?
    private var isArrowDown = true // dynamically updated
    
    private static var current: PopTipView?
    
    init(
        message: String,
        backgroundColor: UIColor = .black,
        textColor: UIColor = .white,
        borderColor: UIColor = .white,
        font: UIFont = .systemFont(ofSize: 14),
        cornerRadius: CGFloat = 8
    ) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        setupLabel(message: message, textColor: textColor, font: font)
        setupShapeLayer(bgColor: backgroundColor, borderColor: borderColor)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel(message: String, textColor: UIColor, font: UIFont) {
        label.text = message
        label.textColor = textColor
        label.font = font
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
    }
    
    private func setupShapeLayer(bgColor: UIColor, borderColor: UIColor) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = bgColor.cgColor
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.lineWidth = 1
        layer.insertSublayer(shapeLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawPopTip()
    }
    
    private func drawPopTip() {
        guard let shapeLayer = layer.sublayers?.first as? CAShapeLayer else { return }
        
        let path = UIBezierPath()
        let radius: CGFloat = 8
        let w = bounds.width
        let h = bounds.height
        
        if isArrowDown {
            let contentHeight = h - arrowSize
            
            path.move(to: CGPoint(x: radius, y: arrowSize))
            path.addLine(to: CGPoint(x: w - radius, y: arrowSize))
            path.addArc(withCenter: CGPoint(x: w - radius, y: radius + arrowSize), radius: radius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: w, y: contentHeight - radius))
            path.addArc(withCenter: CGPoint(x: w - radius, y: contentHeight - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: (w / 2 + arrowSize), y: contentHeight))
            path.addLine(to: CGPoint(x: w / 2, y: h))
            path.addLine(to: CGPoint(x: (w / 2 - arrowSize), y: contentHeight))
            path.addLine(to: CGPoint(x: radius, y: contentHeight))
            path.addArc(withCenter: CGPoint(x: radius, y: contentHeight - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: radius + arrowSize))
            path.addArc(withCenter: CGPoint(x: radius, y: radius + arrowSize), radius: radius, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
            path.close()
            
            label.frame = CGRect(x: 8, y: arrowSize + 8, width: bounds.width - 16, height: bounds.height - arrowSize - 16)
            
        } else {
            let contentHeight = h - arrowSize
            
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: w / 2 - arrowSize, y: 0))
            path.addLine(to: CGPoint(x: w / 2, y: -arrowSize))
            path.addLine(to: CGPoint(x: w / 2 + arrowSize, y: 0))
            path.addLine(to: CGPoint(x: w - radius, y: 0))
            path.addArc(withCenter: CGPoint(x: w - radius, y: radius), radius: radius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: w, y: contentHeight - radius))
            path.addArc(withCenter: CGPoint(x: w - radius, y: contentHeight - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: radius, y: contentHeight))
            path.addArc(withCenter: CGPoint(x: radius, y: contentHeight - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
            path.close()
            
            label.frame = CGRect(x: 8, y: 8, width: bounds.width - 16, height: contentHeight - 16)
        }
        
        shapeLayer.path = path.cgPath
    }
    
    func show(from sourceView: UIView) {
        PopTipView.current?.dismiss()
        PopTipView.current = self
        self.sourceView = sourceView
        
        guard let containerView = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController?.view else { return }
        
        let maxWidth: CGFloat = min(containerView.bounds.width - 32, 250)
        let size = label.sizeThatFits(CGSize(width: maxWidth - 16, height: .greatestFiniteMagnitude))
        let width = min(size.width + 16, maxWidth)
        let height = size.height + 16 + arrowSize
        
        let sourceFrame = sourceView.convert(sourceView.bounds, to: containerView)
        
        let safeTop = containerView.safeAreaInsets.top
        _ = containerView.bounds.height - containerView.safeAreaInsets.bottom
        
        let canShowAbove = (sourceFrame.minY - height - 8) > safeTop
        isArrowDown = canShowAbove
        let y = canShowAbove ? (sourceFrame.minY - height - 8) : (sourceFrame.maxY + 8)
        let x = max(8, min(containerView.bounds.width - width - 8, sourceFrame.midX - width / 2))
        
        frame = CGRect(x: x, y: y, width: width, height: height)
        containerView.addSubview(self)
        
        addTapOutsideRecognizer(to: containerView)
        scheduleAutoDismiss()
        
        self.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    private func addTapOutsideRecognizer(to container: UIView) {
        tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapOutsideRecognizer?.cancelsTouchesInView = false
        if let recognizer = tapOutsideRecognizer {
            container.addGestureRecognizer(recognizer)
        }
    }
    
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        guard let container = superview else { return }
        let tapLocation = gesture.location(in: container)
        if self.frame.contains(tapLocation) { return }
        dismiss()
    }
    
    private func scheduleAutoDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if let recognizer = tapOutsideRecognizer {
            superview?.removeGestureRecognizer(recognizer)
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
            PopTipView.current = nil
        })
    }
}
