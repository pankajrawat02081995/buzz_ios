//
//  ApiEndPoint.swift
//  Broker Portal
//
//  Created by Pankaj on 23/04/25.
//

import Foundation

//MARK: How to use

//static var posts: URL? { url("/posts") }
//static func post(_ id: Int) -> URL? { url("/posts/\(id)") }

enum APIConstants{
    
    static let baseURL = "http://172.105.13.154:9003/api/"
    
    static let version = "v1/mobile-app/"
    
    static var login: URL? { url("users/auth/login") }
    static var signup: URL? { url("users/auth/signup") }
    static var forgotPassword: URL? { url("users/auth/forgot-password") }
    static var socialLogin: URL? { url("users/auth/social") }
    static var logout: URL? { url("users/profile/logout") }
    
    static var petCreate: URL? { url("pets/create") }
    static var petBreed: URL? { url("pets/breeds") }
    static var getPet: URL? { url("pets/") }
    
    static var home: URL? { url("home") }
    static var getVetList: URL? { url("vets/") }
    static func getVetDetails(_ id: String) -> URL? { url("vets/\(id)") }
    static var getAppointments: URL? { url("vets/appointment/my-appointments") }
    static var bookAppointments: URL? { url("vets/appointment/book") }
    static func getAppointmentDetails(_ id: String) -> URL? { url("vets/appointment/\(id)") }
    static func submitDecsion(_ id: String) -> URL? { url("vets/appointment/\(id)/submit-decision") }
    static func cancelAppointment(_ id: String) -> URL? { url("vets/appointment/\(id)/cancel") }
    
    static var getProfile: URL? { url("users/profile/") }
    static var deleteProfile: URL? { url("users/profile/delete") }
    static var updateProfile: URL? { url("users/profile/update") }
    static var changePassword: URL? { url("users/profile/update/password") }
    
    static var createPost: URL? { url("posts/create") }
    static var autoComplete: URL? { url("posts/autoComplete") }
    static var getePost: URL? { url("posts/") }
    static var postComment: URL? { url("posts/comments/create") }
    static var getCommentComment: URL? { url("posts/comments/") }
    static func likePost(_ id: String) -> URL? { url("posts/like/\(id)") }
    static var reportPost: URL? { url("posts/report/submission") }
    static func deletePost(_ id: String) -> URL? { url("posts/\(id)/delete") }
    static func updatePost(_ id: String) -> URL? { url("posts/\(id)/update") }
    static func getMoodHistory(_ id: String) -> URL? { url("posts/\(id)/mood-history")}

    
//    static var noseScaner: URL? { URL(string: "https://zupet-ai.nwaro.com/predict_image") }
    static func noseScaner(_ petType: String) -> URL? { URL(string: "https://zupet-ai.nwaro.com/predict_image_multipart?petType=\(petType)") }
    
    private static func url(_ path: String) -> URL? {
        URL(string: baseURL + version + path)
    }
    
}
