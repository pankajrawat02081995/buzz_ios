import UIKit
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation

final class UniversalFilePicker: NSObject {

    typealias CompletionWithURLs = (_ thumbnails: [UIImage], _ urls: [URL], _ types: [MediaType]) -> Void
    typealias CompletionWithData = (_ images: [UIImage], _ datas: [Data]) -> Void

    private var onCompleteURLs: CompletionWithURLs?
    private var onCompleteData: CompletionWithData?
    private var allowsMultiple: Bool = false
    private weak var presentingController: UIViewController?

    static let shared = UniversalFilePicker()
    private override init() {}

    func presentPicker(
        from controller: UIViewController,
        allowsMultiple: Bool = false,
        returnAsData: Bool = false,
        onCompleteURLs: CompletionWithURLs? = nil,
        onCompleteData: CompletionWithData? = nil
    ) {
        self.presentingController = controller
        self.allowsMultiple = allowsMultiple
        self.onCompleteURLs = onCompleteURLs
        self.onCompleteData = onCompleteData

        let alert = UIAlertController(title: "Choose File", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller.present(alert, animated: true)
    }

    private func presentPhotoLibrary() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = allowsMultiple ? 0 : 5
        config.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presentingController?.present(picker, animated: true)
    }

    private func cleanUp() {
        presentingController = nil
        onCompleteData = nil
        onCompleteURLs = nil
    }

    private func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail error: \(error)")
            return nil
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension UniversalFilePicker: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { cleanUp(); return }

        var thumbnails: [UIImage] = []
        var urls: [URL] = []
        var types: [MediaType] = []

        let group = DispatchGroup()

        for result in results {
            let provider = result.itemProvider

            // Handle Image
            if provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        thumbnails.append(image)
                        urls.append(URL(fileURLWithPath: "")) // placeholder
                        types.append(.image)
                    }
                    group.leave()
                }
            }
            // Handle Video
            else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    guard let url = url else { group.leave(); return }

                    // Copy to temp
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.removeItem(at: tempURL)
                    try? FileManager.default.copyItem(at: url, to: tempURL)

                    if let thumb = self.generateThumbnail(for: tempURL) {
                        thumbnails.append(thumb)
                        urls.append(tempURL)
                        types.append(.video)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.onCompleteURLs?(thumbnails, urls, types)
            self.cleanUp()
        }
    }
}
