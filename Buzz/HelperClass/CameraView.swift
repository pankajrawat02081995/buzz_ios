//
//  CameraView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 01/09/25.
//

import UIKit
import AVFoundation

public final class CameraView: UIView {
    public enum CameraPosition { case front, back }
    public private(set) var position: CameraPosition = .back
    public private(set) var isRunning: Bool = false
    public private(set) var isFlashOn: Bool = false

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "CameraView.SessionQueue")

    // Keep delegate alive until capture finishes
    private var photoDelegates: [PhotoDelegate] = []

    public override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private static let queueKey = DispatchSpecificKey<Void>()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        sessionQueue.setSpecific(key: CameraView.queueKey, value: ())
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        previewLayer.videoGravity = .resizeAspectFill
        sessionQueue.setSpecific(key: CameraView.queueKey, value: ())
    }

    deinit {
        stop()
    }

    // MARK: - Permissions
    public static func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    // MARK: - Shutdown
    public func shutdown(sync: Bool = false) {
        let work: () -> Void = { [weak self] in
            self?.performShutdown()
        }

        if DispatchQueue.getSpecific(key: CameraView.queueKey) != nil {
            work()
        } else if sync {
            sessionQueue.sync(execute: work)
        } else {
            sessionQueue.async(execute: work)
        }
    }

    private func performShutdown() {
        if session.isRunning {
            session.stopRunning()
        }

        if let input = videoInput {
            session.removeInput(input)
            videoInput = nil
        }
        session.outputs.forEach { session.removeOutput($0) }

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.session = nil
        }

        isRunning = false
        photoDelegates.removeAll() // free retained delegates
    }

    // MARK: - Start / Stop
    public func start() {
        CameraView.requestPermission { [weak self] granted in
            guard let self, granted else { return }
            self.sessionQueue.async { self.configureAndStart() }
        }
    }

    private func configureAndStart() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let input = videoInput { session.removeInput(input) }

        let device: AVCaptureDevice? = (position == .back)
            ? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

        guard let camera = device,
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        videoInput = input
        session.addInput(input)

        if session.canAddOutput(photoOutput), !session.outputs.contains(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.session = self?.session
        }

        session.startRunning()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            self?.isRunning = false
        }
    }

    // MARK: - Actions
    public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        if let device = videoInput?.device, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }

        var delegateRef: PhotoDelegate?
        let delegate = PhotoDelegate { [weak self] img in
            completion(img)
            if let ref = delegateRef {
                self?.photoDelegates.removeAll { $0 === ref }
            }
        }
        delegateRef = delegate
        photoDelegates.append(delegate)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    public func toggleFlash() {
        isFlashOn.toggle()
    }

    public func flipCamera() {
        position = (position == .back) ? .front : .back
        refresh()
    }

    public func refresh() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.stopRunning()
            self.configureAndStart()
        }
    }
}

// MARK: - Photo Delegate
private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}
