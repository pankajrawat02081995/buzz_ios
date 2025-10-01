//
//  PetNoseScannerView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 27/07/25.
//

import UIKit
import AVFoundation

//import UIKit
//
//class PetScannerViewController: UIViewController {
//    
//    @IBOutlet weak var scannerView: PetNoseScannerView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Simulate detection every 2 seconds for testing
//        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
//            let isCorrect = Bool.random()
//            self?.scannerView.updateOverlay(isCorrect: isCorrect)
//        }
//    }
//}

class PetNoseScannerView: UIView {
    
    private let shapeLayer = CAShapeLayer()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let session = AVCaptureSession()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
        setupOverlay()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            if session.canAddInput(input) {
                session.addInput(input)
            }
            session.commitConfiguration()
            
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            layer.insertSublayer(previewLayer, at: 0)
            session.startRunning()
        } catch {
            print("Camera error:", error)
        }
    }
    
    private func setupOverlay() {
        shapeLayer.lineWidth = 3
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.orange.cgColor // default
        layer.addSublayer(shapeLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        
        // Create triangle path dynamically
        let w = bounds.width
        let h = bounds.height
        
        let triangle = UIBezierPath()
        triangle.move(to: CGPoint(x: w/2 - 60, y: h/2 - 40))
        triangle.addLine(to: CGPoint(x: w/2 + 60, y: h/2 - 40))
        triangle.addLine(to: CGPoint(x: w/2, y: h/2 + 60))
        triangle.close()
        
        shapeLayer.path = triangle.cgPath
    }
    
    func updateOverlay(isCorrect: Bool) {
        shapeLayer.strokeColor = isCorrect ? UIColor.green.cgColor : UIColor.orange.cgColor
        
        // Pulse animation
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.05
        pulse.duration = 0.3
        pulse.autoreverses = true
        shapeLayer.add(pulse, forKey: "pulse")
    }
}
