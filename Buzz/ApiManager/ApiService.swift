//
//  ApiService.swift
//  WebService
//
//  Created by Pankaj on 18/02/25.
//

import Foundation
import Network

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum APIRequest {
    case getRequest(url: URL, headers: [String: Any]?)
    case postRequest(url: URL, body: Data?,method:HTTPMethod = .post, headers: [String: Any]?)
    case uploadMultipart(url: URL, parameters: [String: Any], files: [File], headers: [String: Any]?)
    case restRequest(url: URL, method: HTTPMethod, body: Data?, headers: [String: Any]?)
    
    public struct File {
        public let data: Data
        public let fileName: String
        public let fieldName : String
        public let mimeType: String
    }
}

// MARK: - API Errors
enum APIError: Error,LocalizedError {
    
    case networkUnavailable
    case invalidResponse
    case networkError(String)
    case serverError(Int)
    case decodingError(String)
    case unknown(String)
    case unauthorized
    case forbidden
    case clientError
    case notFound
    case authenticationFailed
    case defaultMessage(String)
    
    var errorMessage: String {
        switch self {
        case .networkUnavailable:
            return "The Internet connection appears to be offline. Please check your connection and try again."
        case .invalidResponse:
            return "Invalid response from the server. Please try again later."
        case .networkError(let message):
            return "Network error occurred: \(message). Please check your connection."
        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."
        case .decodingError(let message):
            return "Failed to process the response: \(message)."
        case .unknown(let message):
            return "An unexpected error occurred: \(message). Please try again."
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in again."
        case .forbidden:
            return "Access denied. You do not have permission to access this resource."
        case .clientError:
            return "There was an error in your request. Please check and try again."
        case .notFound:
            return "The requested resource could not be found. Please verify the URL and try again."
        case .authenticationFailed:
            return "Your login session has timed out. Please sign in again."
        case .defaultMessage(let message):
            return message
        }
    }
    // ✅ Override `LocalizedError`'s `errorDescription` to return `errorMessage`
    var errorDescription: String? {
        return errorMessage
    }
}

// Lightweight API manager with memory-efficient calls
public actor APIManager {
    
    public static var shared = APIManager()
    
    private let session: URLSession
    private let cache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000, diskPath: nil)
    private var isConnected = false
    private let monitor = NWPathMonitor()
    private var pendingRequests: [APIRequest] = []
    var progressHandler: ((APIRequest.File, Double) -> Void)?
    private let userDefaults = UserDefaults.standard
    private let loaderManager = LoaderManager()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        session = URLSession(configuration: config)
    }
    
    // MARK: - Async Initializer
    public static func initializeShared() async {
        let instance = APIManager()
        await instance.awaitInitialNetworkStatus()
        shared = instance
    }
    
    // MARK: - Await Initial Network Status
    private func awaitInitialNetworkStatus() async {
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue.global(qos: .background)
            
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                Task {
                    await self.updateConnectionStatus(isConnected: path.status == .satisfied)
                    continuation.resume()
                }
                
                // Set new handler for future updates
                self.monitor.pathUpdateHandler = { [weak self] path in
                    guard let self = self else { return }
                    Task { await self.updateConnectionStatus(isConnected: path.status == .satisfied) }
                }
            }
            
            monitor.start(queue: queue)
        }
    }
    
    private func updateConnectionStatus(isConnected: Bool) async {
        self.isConnected = isConnected
        if isConnected {
            await retryPendingRequests()
        }
    }
    
    /// 📌 Handle API Requests with Offline Support
    public func handleRequest(_ request: APIRequest,isloaderHide:Bool?=true, progress: ((APIRequest.File, Double) -> Void)? = nil) async throws -> Data {
        
        if isloaderHide ?? false{
            await loaderManager.showLoadingWithDelay()
        }
        // If offline and cached data exists, return cached response
        if !isConnected, let cachedData = getCachedData(for: request) {
            return cachedData
        }
        
        // Try fetching data from API
        do {
            let responseData: Data
            switch request {
            case .getRequest(let url, let headers):
                responseData = try await fetchData(from: url, headers: headers)
            case .postRequest(let url, let body,let method ,let headers):
                responseData = try await sendData(to: url, method: method, body: body, headers: headers)
            case .uploadMultipart(let url, let parameters, let files, let headers):
                responseData = try await uploadMultipart(to: url, parameters: parameters, files: files, headers: headers)
            case .restRequest(let url, let method, let body, let headers):
                responseData = try await sendData(to: url, method: method, body: body, headers: headers)
            }
            
            // Cache successful response
            cacheData(responseData, for: request)
            await loaderManager.hideLoading()
            return responseData
            
        } catch {
            // If offline, store failed request for retry
            await Log.debug("Is Connected with internet \(self.isConnected)")
            await Log.debug("Error \(error.localizedDescription)")
            if !isConnected {
                addPendingRequest(request)
            }
            await loaderManager.hideLoading()
            throw error
        }
    }
    
    /// 📌 Cache API Response
    private func cacheData(_ data: Data, for request: APIRequest) {
        let key = cacheKey(for: request)
        userDefaults.set(data, forKey: key)
    }
    
    /// 📌 Retrieve Cached Data
    private func getCachedData(for request: APIRequest) -> Data? {
        let key = cacheKey(for: request)
        return userDefaults.data(forKey: key)
    }
    
    /// 📌 Generate Unique Cache Key
    private func cacheKey(for request: APIRequest) -> String {
        switch request {
        case .getRequest(let url, _): return url.absoluteString
        case .postRequest(let url, _, _, _): return url.absoluteString
        case .uploadMultipart(let url, _, _, _): return url.absoluteString
        case .restRequest(let url, _, _, _): return url.absoluteString
        }
    }
    
    /// 📌 Store Failed Requests
    private func addPendingRequest(_ request: APIRequest) {
        pendingRequests.append(request)
    }
    
    /// 📌 Retry Failed Requests when Internet is Back
    private func retryPendingRequests() async {
        guard isConnected else { return }
        
        for request in pendingRequests {
  
            do {
                let _ = try await handleRequest(request)
                Log.debug("✅ Retried API: \(request)")
            } catch {
                Log.debug("\("❌ Retry Failed: \(error.localizedDescription)")")
            }
        }
        pendingRequests.removeAll()
    }
    
    
    // MARK: - GET Request (Efficient Memory Usage)
    private func fetchData(from url: URL, headers: [String: Any]?) async throws -> Data {
        guard isConnected else {
            Log.debug("Error is \(APIError.networkUnavailable.localizedDescription)")
            throw APIError.networkUnavailable
        }
        
        Log.debug("**** Api: \(url.absoluteString)")
        Log.debug("Bearer \(await UserDefaultsManager.shared.fatchCurentUser()?.token ?? "")")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(await UserDefaultsManager.shared.fatchCurentUser()?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        setHeaders(request: &request, headers: headers)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        Log.debug("Response : \(try data.dataToDictionary())")
        return autoreleasepool { data }
    }
    
    // MARK: - Generic Request (For POST, PUT, DELETE)
    private func sendData(to url: URL, method: HTTPMethod, body: Data?, headers: [String: Any]?) async throws -> Data {
        guard isConnected else { throw APIError.networkUnavailable }
        
        func makeRequest() async throws -> (Data, HTTPURLResponse) {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if body != nil{
                request.httpBody = body
            }
            request.setValue("Bearer \(await UserDefaultsManager.shared.fatchCurentUser()?.token ?? "")", forHTTPHeaderField: "Authorization")
            Log.debug("Bearer \(await UserDefaultsManager.shared.fatchCurentUser()?.token ?? "")")
            setHeaders(request: &request, headers: headers)
            Log.debug(request)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (data, httpResponse)
        }
        
        let (data, response) = try await makeRequest()
        Log.debug("Response : \(try data.dataToDictionary())")
        if response.statusCode == 200 {
            return data
        } else if response.statusCode == 500 {
            throw APIError.defaultMessage(try data.dataToDictionary()["message"] as? String ?? "")
        } else if response.statusCode == 401 || response.statusCode == 400{
//            try await refreshTokenIfNeeded()
            let (retryData, retryResponse) = try await makeRequest()
            guard retryResponse.statusCode == 200 else {
                if response.statusCode == 400{
                    return data
                }else{
                    throw APIError.authenticationFailed
                }
            }
            return retryData
        } else {
            throw APIError.serverError(response.statusCode)
        }
    }
    
    // MARK: - Multipart Upload with Progress Tracking
    private func uploadMultipart(
        to url: URL,
        parameters: [String: Any],
        files: [APIRequest.File],
        headers: [String: Any]?
    ) async throws -> Data {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        request.setValue(
//            "Bearer \(await UserDefaultsManager.shared.get(SigninModel.self, forKey: UserDefaultsKey.LoginResponse)?.data?.token ?? "")",
//            forHTTPHeaderField: "Authorization"
//        )
        
        setHeaders(request: &request, headers: headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = URLSession(configuration: .default)
            
            // Create multipart body
            let body = createMultipartBody(parameters: parameters, files: files, boundary: boundary)
            request.httpBody = body
            
            Log.debug("🚀 Uploading to: \(request.url?.absoluteString ?? "Unknown URL")")
            
            let task = session.dataTask(with: request) { data, response, error in
                
                if let error = error {
                    Log.error("❌ Upload failed with error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    Log.debug("📡 Response status: \(httpResponse.statusCode)")
                    Log.debug("📩 Headers: \(httpResponse.allHeaderFields)")
                }
                
                if let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        Log.debug("✅ Response body: \(jsonString)")
                    } else {
                        Log.debug("✅ Response received but not UTF-8 decodable (\(data.count) bytes)")
                    }
                    continuation.resume(returning: data)
                } else {
                    let noDataError = NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    Log.error("❌ No data received from server")
                    continuation.resume(throwing: noDataError)
                }
            }
            
            task.resume()
        }
    }

    // MARK: - Helper: Create Multipart Form Body
    private func createMultipartBody(parameters: [String: Any], files: [APIRequest.File], boundary: String) -> Data {
        var body = Data()
        
        // Text parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // File parameters
        for file in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }

    // MARK: - Helper: Set Custom Headers
    private func setHeaders(request: inout URLRequest, headers: [String: Any]?) {
        headers?.forEach { key, value in
            request.setValue("\(value)", forHTTPHeaderField: key)
        }
    }

    
//    private func refreshTokenIfNeeded() async throws {
//        // Assuming you store refreshToken and can update accessToken
//        let refreshToken = await UserDefaultsManager.shared.get(SigninModel.self, forKey: UserDefaultsKey.LoginResponse)?.refreshToken
//        guard let refreshToken =
//                refreshToken else {
//            throw APIError.authenticationFailed
//        }
//        
//        guard let refreshURL = APIConstants.refreshToken else { return }
//        var request = URLRequest(url: refreshURL)
//        request.httpMethod = "GET"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
//        
//        let (data, response) = try await session.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            AuthHandler.shared.handleUnauthorized()
//            await ToastManager.shared.showToast(message: APIError.authenticationFailed.errorMessage)
//            return
//        }
//        
//        // Parse new token
//        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
//        let newAccessToken = json?["access_token"] as? String ?? ""
//        //        let newRefreshToken = json?["refresh_token"] as? String
//        
//        await self.updateUserDefaultModel(accessToken:newAccessToken,refreshToken:"")
//    }
    
}

// MARK: - Upload Task Delegate for Progress Tracking
private class UploadTaskDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    weak var task: URLSessionUploadTask?
    var progressHandler: ((APIRequest.File, Double) -> Void)?
    let continuation: CheckedContinuation<Data, Error>
    
    init(progressHandler: ((APIRequest.File, Double) -> Void)?, continuation: CheckedContinuation<Data, Error>) {
        self.progressHandler = progressHandler
        self.continuation = continuation
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        if let file = getCurrentUploadingFile(task) {
            DispatchQueue.main.async {
                self.progressHandler?(file, progress)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        continuation.resume(returning: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation.resume(throwing: error)
        }
    }
    
    private func getCurrentUploadingFile(_ task: URLSessionTask) -> APIRequest.File? {
        // Implement logic to match task with file if needed
        return nil
    }
}

// MARK: - Data Extension for Efficient Appending
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
