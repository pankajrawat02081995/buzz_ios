//
//  CommonApi.swift
//  Zupet
//
//  Created by Pankaj Rawat on 08/08/25.
//

import UIKit
import AVFoundation

//MARK: Breed Model

struct BreedResponse: Codable {
    let success: Bool?
    let data: BreedData?
}

struct BreedData: Codable {
    let dogBreeds: [String]?
    let catBreeds: [String]?
    let dogColors: [String]?
    let catColors: [String]?
}


@MainActor
final class APIService {
    
    static let shared = APIService() // Singleton instance
    private let loaderManager = LoaderManager()
    private init() {}
    
    func fatchBreed() {
        Task {
            do {
                guard let url = APIConstants.petBreed else { return }
                let result: BreedResponse = try await SilentAPIManager.shared.fetchDataSilently(
                    url: url,
                    type: BreedResponse.self
                )
                Log.debug(result)
                await UserDefaultsManager.shared.set(result.data, forKey: UserDefaultsKey.BreedData)
                debugPrint(await UserDefaultsManager.shared.get(BreedData.self, forKey: UserDefaultsKey.BreedData)?.catBreeds ?? [])
                
            } catch {
                Log.debug(error.localizedDescription)
            }
        }
    }
    
    func forgotPassword(parameters: [String:Any],viewController: UIViewController,isReset:Bool=false,isResend:Bool=false)  {
        // Use Swift concurrency with weak self to avoid retain cycles
        Task { [weak self] in
            // Get the signup URL from constants
            guard let url = APIConstants.forgotPassword else {
                await ToastManager.shared.showToast(message: "Invalid URL")
                return
            }
            
            do {
                // Convert parameters to JSON Data
                let jsonData = try await APIManagerHelper.shared.convertIntoData(from: parameters)
                
                // Perform the network request and decode response into SignupModel
                let response: BaseModel = try await APIManagerHelper.shared.handleRequest(
                    .postRequest(url: url, body: jsonData, method: .post, headers: [:]),
                    responseType: BaseModel.self
                )
                
                // Handle successful response
                if response.success == true {
                    // You can call delegate or closure to notify view
                    if isResend == false{
                        if isReset{
                            Log.debug("Set Root")
                            viewController.navigationController?.popToRootViewController(animated: true)
                        }else{
//                            viewController.push(ResetPassword.self, from: .main){ [weak self] vc in
//                                guard self != nil else { return }
//                                vc.email = parameters["email"] as? String ?? ""
//                            }
                        }
                    }
                }
                
                // Show message to user (non-blocking on main thread)
                await ToastManager.shared.showToast(message: response.message ?? "Forgot Password completed.")
                
            } catch {
                // Show error message to user
                await ToastManager.shared.showToast(message: error.localizedDescription)
            }
        }
    }
}

final class SilentAPIManager {
    static let shared = SilentAPIManager()
    private init() {}
    
    private var cacheMemory: [String: Data] = [:]
    
    func fetchDataSilently<T: Decodable>(url: URL, type: T.Type) async throws -> T {
        let cacheKey = url.absoluteString
        
        // 1. Return cached value instantly if available
        if let localData = cacheMemory[cacheKey] ?? UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(T.self, from: localData) {
            // Trigger silent refresh in background
            Task {
                try? await self.refreshData(url: url, type: type)
            }
            return decoded
        }
        
        // 2. No cache? Fetch from server
        return try await refreshData(url: url, type: type)
    }
    
    private func refreshData<T: Decodable>(url: URL, type: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(try await "Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Cache
        cacheMemory[url.absoluteString] = data
        UserDefaults.standard.set(data, forKey: url.absoluteString)
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func getAuthToken() async throws -> String {
        return await UserDefaultsManager.shared
            .get(UserData.self, forKey: UserDefaultsKey.LoginResponse)?
            .token ?? ""
    }
}

struct BaseModel: Codable {
    let success : Bool
    let message: String
}

struct UserData: Codable {
    let token: String?
    let id: String?
    let fullName: String?
    let avatar: String?
    let email: String?
    let phone : String?
    var petsCount : Int?
    let countryCode : String?
    
    enum CodingKeys: String, CodingKey {
        case token
        case petsCount
        case countryCode
        case phone
        case id = "_id"
        case fullName
        case avatar
        case email
    }
}


struct UploadResponseData: Codable {
    let type: String
    let url: String
    let caption: String
    let videoThumbnailUrl : String
}

struct UploadResponse:Codable{
    let success : Bool
    let data : UploadResponseData
    let message: String
}

enum MediaType {
    case image
    case video
}

struct MediaItem {
    let id: UUID
    var type: MediaType
    var imageURL: String?
    var videoURL: URL?
    var thumbnail: UIImage?
    var isLocal: Bool?
    var serverVideoURL: String?
    var serverThumnailURL: String?
    
    // ✅ Custom initializer with default values
    init(
        id: UUID = UUID(),
        type: MediaType,
        imageURL: String? = nil,
        videoURL: URL? = nil,
        thumbnail: UIImage? = nil,
        isLocal: Bool? = true,
        serverVideoURL: String? = nil,
        serverThumnailURL: String? = nil
    ) {
        self.id = id
        self.type = type
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.serverVideoURL = serverVideoURL
        self.serverThumnailURL = serverThumnailURL
        self.thumbnail = thumbnail
        self.isLocal = isLocal
    }
}

extension APIService {
    
    // Public entry
    func upload(items: [MediaItem]) async throws -> [UploadResponse] {
        var responses: [UploadResponse] = []
        
        await MainActor.run {
            loaderManager.showLoadingWithDelay()   // 🔹 Show loader
        }
        
        // ✅ Always hide loader when function ends (success OR error)
        defer {
            Task { @MainActor in
                loaderManager.hideLoading()
            }
        }
        
        do {
            for item in items {
                if item.isLocal == true{
                    if let response = try await uploadSingle(item: item) {
                        responses.append(response)
                    }
                }
            }
        } catch {
            Log.debug("❌ Upload failed: \(error.localizedDescription)")
            throw error   // propagate error to caller
        }
        
        return responses
    }
    
    // Upload a single item
    private func uploadSingle(item: MediaItem) async throws -> UploadResponse? {
        switch item.type {
        case .image:
            guard let data = item.thumbnail?.toWebPData() else {
                throw NSError(
                    domain: "Upload",
                    code: -10,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"]
                )
            }
            return try await uploadMultipart(
                data: data,
                fileName: "image.jpg",
                mimeType: "image/jpeg"
            )
            
        case .video:
            if let url = item.videoURL {
                let compressedURL = try await compressVideoIfNeeded(url: url)
                let data = try Data(contentsOf: compressedURL)
                return try await uploadMultipart(
                    data: data,
                    fileName: "video.mp4",
                    mimeType: "video/mp4"
                )
            }
        }
        return nil
    }
    
    // Compress video (max 30s check)
    private func compressVideoIfNeeded(url: URL) async throws -> URL {
        let asset = AVAsset(url: url)
        
        // Duration check
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration <= 30 else {
            throw NSError(
                domain: "Upload",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Video exceeds 30 seconds"]
            )
        }
        
        let preset = AVAssetExportPresetMediumQuality
        let compressedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                continuation.resume(throwing: NSError(
                    domain: "Upload",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Video compression not supported"]
                ))
                return
            }
            
            exportSession.outputURL = compressedURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: compressedURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: exportSession.error ?? NSError(
                        domain: "Upload",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Video compression failed"]
                    ))
                default: break
                }
            }
        }
    }
    
    // Multipart API (for both images & videos)
    private func uploadMultipart(
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> UploadResponse {

        let url = URL(string: "http://172.105.13.154:9003/api/v1/mobile-app/media/save")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 🔑 Correct synchronous token fetch
        let token = await UserDefaultsManager.shared.fatchCurentUser()?.token ?? ""
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        do {
            let (responseData, response) = try await URLSession.shared.upload(for: request, from: body)

            if let httpResponse = response as? HTTPURLResponse {
                Log.debug("📡 Upload Response Status: \(httpResponse.statusCode)")
            }

            if let rawString = String(data: responseData, encoding: .utf8) {
                Log.debug("📦 Raw Response: \(rawString)")
            }

            let decoded = try JSONDecoder().decode(UploadResponse.self, from: responseData)
            Log.debug("✅ Decoded Response: \(decoded)")
            return decoded

        } catch {
            Log.debug("❌ Upload request failed: \(error.localizedDescription)")
            throw error
        }
    }

}
