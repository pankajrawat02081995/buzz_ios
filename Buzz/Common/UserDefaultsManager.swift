//
//  UserDefaultsManager.swift
//  Broker Portal
//
//  Created by Pankaj on 24/04/25.
//

import Foundation

struct UserDefaultsKey{
    static let LoginResponse = "loginResponse"
    static let BreedData = "BreedData"
    static let Pets = "Pets"
    static let SelectedAgencies = "SelectedAgencies"
}

enum UserType {
    case admin
    case normal
}

actor UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Save
    func set<T: Encodable>(_ value: T, forKey key: String) async {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    
    func set<T>(_ value: T, forKey key: String) async {
        defaults.set(value, forKey: key)
    }
    
    // MARK: - Get
    func get<T: Decodable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func get<T>(_ type: T.Type, forKey key: String) async -> T? {
        return defaults.value(forKey: key) as? T
    }
    
    // MARK: - Remove
    func remove(forKey key: String) async {
        defaults.removeObject(forKey: key)
    }
    
    // MARK: - Clear All
    func clearAll() async {
        // Clear any in-app cache first (if exists)
//        await SigninModel.userCache.clear()
        
        // Remove all keys one by one
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        
        // Just to be extra safe: remove persistent domain
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            UserDefaults.standard.synchronize()
        }
        Log.debug("✅ UserDefaults cleared. Remaining keys:  \(defaults.dictionaryRepresentation().keys)")
    }
 
    
    func fatchCurentUser() async -> UserData?{
        return await UserDefaultsManager.shared.get(UserData.self, forKey: UserDefaultsKey.LoginResponse)
    }
    
}
