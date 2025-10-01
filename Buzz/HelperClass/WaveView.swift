//
//  WaveView.swift
//  Zupet
//
//  Created by Pankaj Rawat on 24/08/25.
//

import Foundation
import UIKit
import AVFoundation
import Accelerate


// MARK: - Waveform View
final class WaveformView: UIView {
    var samples: [CGFloat] = [] { didSet { setNeedsDisplay() } }
    var progress: CGFloat = 0 { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard !samples.isEmpty else { return }
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.clear(rect)

        let midY = rect.midY
        let step = rect.width / CGFloat(samples.count)

        for (i, amp) in samples.enumerated() {
            let x = CGFloat(i) * step
            let height = max(2, amp * rect.height)
            let barRect = CGRect(x: x, y: midY - height/2, width: step*0.8, height: height)

            ctx.setFillColor(UIColor.lightGray.cgColor)
            ctx.fill(barRect)

            if CGFloat(i)/CGFloat(samples.count) <= progress {
                ctx.setFillColor(UIColor.systemBlue.cgColor)
                ctx.fill(barRect)
            }
        }
    }
}

// MARK: - Audio Player Helper
final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    var onProgress: ((Double) -> Void)?
    var onFinish: (() -> Void)?

    func play(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
        player?.play()

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
            guard let self, let p = self.player else { t.invalidate(); return }
            if p.isPlaying {
                self.onProgress?(p.currentTime / p.duration)
            } else {
                t.invalidate()
            }
        }
    }

    func pause() { player?.pause() }
    func stop() { player?.stop() }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

// MARK: - Voice Message Cell
class VoiceMessageCell: UITableViewCell {
    static let reuseID = "VoiceMessageCell"

    private let playButton = UIButton(type: .system)
    private let waveform = WaveformView()
    private let player = AudioPlayer()
    private var audioURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [playButton, waveform])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            waveform.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Player callbacks
        player.onProgress = { [weak self] prog in
            self?.waveform.progress = CGFloat(prog)
        }
        player.onFinish = { [weak self] in
            self?.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            self?.waveform.progress = 0
        }
    }

    func configure(audioURL: URL, samples: [CGFloat]) {
        self.audioURL = audioURL
        self.waveform.samples = samples
    }

    @objc private func togglePlay() {
        guard let url = audioURL else { return }
        if playButton.currentImage == UIImage(systemName: "play.fill") {
            try? player.play(url: url)
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
}

import AVFoundation

func generateWaveformSamples(from url: URL, samplesCount: Int = 50) -> [CGFloat] {
    let asset = AVAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else { return [] }

    do {
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false
        ]

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)

        // ✅ Must add before startReading
        guard reader.canAdd(output) else { return [] }
        reader.add(output)

        // ✅ Must start reading
        reader.startReading()

        var sampleData: [Float] = []

        while reader.status == .reading,
              let buffer = output.copyNextSampleBuffer(),
              let blockBuffer = CMSampleBufferGetDataBuffer(buffer) {
            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = Data(count: length)
            data.withUnsafeMutableBytes { ptr in
                if let addr = ptr.baseAddress {
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: addr)
                }
            }

            let samples = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Int16] in
                let bufferPointer = ptr.bindMemory(to: Int16.self)
                return Array(bufferPointer)
            }

            let floats = samples.map { Float($0) / Float(Int16.max) }
            sampleData.append(contentsOf: floats)
            CMSampleBufferInvalidate(buffer)
        }

        if reader.status == .failed {
            print("Reader failed: \(reader.error?.localizedDescription ?? "unknown error")")
        }

        guard !sampleData.isEmpty else { return [] }

        // Downsample to requested bar count
        let chunkSize = max(1, sampleData.count / samplesCount)
        var result: [CGFloat] = []
        for i in stride(from: 0, to: sampleData.count, by: chunkSize) {
            let chunk = sampleData[i..<min(i+chunkSize, sampleData.count)]
            let rms = sqrt(chunk.map { $0 * $0 }.reduce(0, +) / Float(chunk.count))
            result.append(CGFloat(rms))
        }

        // Normalize to 0...1
        if let maxVal = result.max(), maxVal > 0 {
            result = result.map { $0 / maxVal }
        }

        return result

    } catch {
        print("Error creating reader: \(error)")
        return []
    }
}


class ChatVC: UITableViewController {
    let messages: [(url: URL, samples: [CGFloat])] = [
        // Fill with your audio file URLs + waveform samples
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(VoiceMessageCell.self, forCellReuseIdentifier: VoiceMessageCell.reuseID)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VoiceMessageCell.reuseID, for: indexPath) as! VoiceMessageCell
        let remoteURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!

        downloadAudio(from: remoteURL) { localURL in
            if let localURL {
                let samples = generateWaveformSamples(from: localURL, samplesCount: 60)
                DispatchQueue.main.async {
                    cell.configure(audioURL: localURL, samples: samples)
                }
            }
        }
        return cell
    }
    
    func downloadAudio(from remoteURL: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            if let tempURL, error == nil {
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(remoteURL.lastPathComponent)
                try? FileManager.default.removeItem(at: localURL) // remove old if exists
                do {
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    completion(localURL) // ✅ ready to use with AVAssetReader
                } catch {
                    print("Move error: \(error)")
                    completion(nil)
                }
            } else {
                print("Download error: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
            }
        }
        task.resume()
    }

}
