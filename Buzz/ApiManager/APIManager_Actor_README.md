
# **APIManager Actor - README**

### **Introduction**

This APIManager actor is designed to simplify API networking tasks in Swift using the `async/await` model and `actor` for concurrency safety. The actor supports the following functionalities:
- **GET** requests
- **POST** requests with optional body
- **Multipart uploads** (images, videos, etc.)
- **General RESTful requests** (GET, POST, PUT, DELETE)

### **Features**
- **Concurrency-safe**: All requests are handled inside an actor to ensure thread safety.
- **Modular**: Each API request type (GET, POST, etc.) is encapsulated in an enum and processed through a generic `handleRequest` function.
- **Multipart support**: Upload multiple images or videos with or without additional parameters.
- **Ease of Use**: Simplified API interaction with enums to define parameters.

---

### **Installation**

Simply copy the `APIManager` actor and supporting code to your project. It should be compatible with **Swift 5.5** or later, due to the use of `async/await` and `actor`.

### **How to Use**

The APIManager actor can be used by calling the `handleRequest` function with different types of requests. Each request type is specified through the `APIRequest` enum. 

---

### **Step 1: Import Required Modules**

Make sure to import the necessary modules for networking:

```swift
import Foundation
```

---

### **Step 2: Creating an APIManager Instance**

To use the APIManager actor, you first need to create an instance of the actor:

```swift
let apiManager = APIManager()
```

---

### **Step 3: Making GET Requests**

To make a **GET** request, use the `.getRequest` case from the `APIRequest` enum:

```swift
guard let url = URL(string: "https://jsonplaceholder.typicode.com/users/1") else {
    print("Invalid URL")
    return
}

do {
    let response = try await apiManager.handleRequest(.getRequest(url: url))
    print("Response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("Error: \(error)")
}
```

### **Step 4: Making POST Requests with Optional Body**

For **POST** requests, use the `.postRequest` case from the `APIRequest` enum. You can pass an optional body (e.g., JSON data):

```swift
guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
    print("Invalid URL")
    return
}

let parameters: [String: Any] = ["title": "foo", "body": "bar", "userId": 1]
let body = try! JSONSerialization.data(withJSONObject: parameters, options: [])

do {
    let response = try await apiManager.handleRequest(.postRequest(url: url, body: body))
    print("Post Response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("Error: \(error)")
}
```

### **Step 5: Uploading Multiple Files (Images + Video)**

For **multipart** file uploads, use the `.uploadMultipart` case. You can pass multiple files as an array of `File` objects. Each file contains `data`, `fileName`, and `mimeType`.

Here’s how to upload multiple files, including images and video:

```swift
guard let url = URL(string: "https://yourapi.com/upload") else {
    print("Invalid URL")
    return
}

let parameters = ["userId": "1"]

// Replace with actual file data
let image1Data = Data() // Example image data
let image2Data = Data() // Example image data
let videoData = Data()  // Example video data

let files = [
    APIRequest.File(data: image1Data, fileName: "image1.jpg", mimeType: "image/jpeg"),
    APIRequest.File(data: image2Data, fileName: "image2.jpg", mimeType: "image/jpeg"),
    APIRequest.File(data: videoData, fileName: "video.mp4", mimeType: "video/mp4")
]

do {
    let response = try await apiManager.handleRequest(.uploadMultipart(url: url, parameters: parameters, files: files))
    print("Upload response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("Error: \(error)")
}
```

---

### **Step 6: Uploading a Single Image and Video**

For uploading a **single image and video** together, you can use the same `uploadMultipart` method:

```swift
guard let url = URL(string: "https://yourapi.com/upload") else {
    print("Invalid URL")
    return
}

let parameters = ["userId": "1"]

// Replace with actual file data for image and video
let imageData = Data() // Example image data
let videoData = Data() // Example video data

let files = [
    APIRequest.File(data: imageData, fileName: "image.jpg", mimeType: "image/jpeg"),
    APIRequest.File(data: videoData, fileName: "video.mp4", mimeType: "video/mp4")
]

do {
    let response = try await apiManager.handleRequest(.uploadMultipart(url: url, parameters: parameters, files: files))
    print("Upload response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("Error: \(error)")
}
```

---

### **Step 7: Sending General RESTful Requests (GET, POST, PUT, DELETE)**

The **RESTful** request function handles GET, POST, PUT, and DELETE requests. You can specify the HTTP method and pass the body if needed:

```swift
guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
    print("Invalid URL")
    return
}

let parameters: [String: Any] = ["title": "updated title", "body": "updated body", "userId": 1]
let body = try! JSONSerialization.data(withJSONObject: parameters, options: [])

do {
    let response = try await apiManager.handleRequest(.restRequest(url: url, method: .put, body: body))
    print("PUT response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("Error: \(error)")
}
```

---

### **Step 8: Handling Errors**

Each of the API functions uses Swift’s error handling. If an error occurs during any API call, it will throw an error that can be caught using `do-catch` blocks. You can access the error message to diagnose what went wrong.

For example:

```swift
do {
    let response = try await apiManager.handleRequest(.getRequest(url: url))
    print("Response: \(String(data: response, encoding: .utf8) ?? "")")
} catch {
    print("An error occurred: \(error.localizedDescription)")
}
```

---

### **Additional Notes**

- **Concurrency**: The `APIManager` is an actor, which ensures that requests are handled serially in a thread-safe manner. This is especially useful for managing state across multiple requests.
- **Multipart Uploads**: The multipart upload handles both single and multiple file uploads. Files are uploaded with their respective metadata (filename and MIME type).
- **Error Handling**: The code uses Swift's `throws` to propagate errors. When using the API manager, be sure to use `do-catch` to handle potential errors.

---

### **Conclusion**

The `APIManager` actor simplifies working with APIs in Swift using modern concurrency tools (`async/await` and `actor`). This guide provides a step-by-step explanation of how to perform GET and POST requests, upload multiple files, and handle general RESTful requests.

By following this documentation, you should be able to integrate API requests into your project in a clean and efficient way.
