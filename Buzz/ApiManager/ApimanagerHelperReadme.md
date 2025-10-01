# APIManagerHelper

## Overview
APIManagerHelper is a lightweight and efficient Swift singleton class designed to handle API requests using modern concurrency features such as `async/await` and `actor`. It supports GET, POST, multipart uploads, and JSON encoding/decoding.

## Features
- **Singleton Access**: Easily accessible through `APIManagerHelper.shared`.
- **Async/Await Support**: Modern concurrency for better performance.
- **Memory Efficient**: Utilizes `actor` for safe API handling.
- **JSON Encoding/Decoding**: Converts models and parameters to/from JSON.
- **Multipart Upload Support**: Handles image/video uploads with progress tracking.

## Installation
Simply copy `APIManagerHelper.swift` and `APIManager.swift` into your project.

## Usage

### 1. GET Request Example
```swift
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }

    private func fetchData() {
        guard let url = URL(string: "https://api.example.com/data") else { return }

        Task {
            do {
                let response: YourModel = try await APIManagerHelper.shared.handleRequest(.getRequest(url: url, headers: nil), responseType: YourModel.self)
                print("API Response:", response)
            } catch {
                print("API Error:", error)
            }
        }
    }
}

struct YourModel: Codable {
    let id: Int
    let name: String
}
```

### 2. POST Request Example
```swift
Task {
    let parameters: [String: Any] = ["key": "value"]
    let jsonData = try await APIManagerHelper.shared.convertIntoData(from: parameters)
    
    guard let url = URL(string: "https://api.example.com/post") else { return }
    
    do {
        let response: YourModel = try await APIManagerHelper.shared.handleRequest(.postRequest(url: url, body: jsonData, headers: nil), responseType: YourModel.self)
        print("POST Response:", response)
    } catch {
        print("POST Error:", error)
    }
}
```

### 3. Multipart Upload Example
```swift
Task {
    guard let url = URL(string: "https://api.example.com/upload") else { return }
    let imageData = Data() // Load your image data here
    let file = APIRequest.File(data: imageData, fileName: "image.jpg", mimeType: "image/jpeg")
    
    do {
        let response = try await APIManagerHelper.shared.handleRequest(
            .uploadMultipart(url: url, parameters: ["userId": "123"], files: [file], headers: nil),
            responseType: YourModel.self
        )
        print("Upload Response:", response)
    } catch {
        print("Upload Error:", error)
    }
}
```

## Error Handling
The APIManagerHelper handles multiple error cases:
- **Invalid Response**: If the HTTP response is not 200 OK.
- **Network Errors**: Catches network failures.
- **Decoding Errors**: Handles JSON decoding failures.
- **Server Errors**: Returns HTTP status codes if the request fails.

## License
This project is available under the MIT License.

## Author
Developed by [Your Name].
