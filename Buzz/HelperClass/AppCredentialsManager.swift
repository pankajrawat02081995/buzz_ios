//
//  AppCredentialsManager.swift
//  Zupet
//
//  Created by Pankaj Rawat on 12/08/25.
//

import Foundation
import Security

struct CredentialsManager {
    private let emailKey = "userEmail"
    private let rememberMeKey = "rememberMe"
    private let passwordAccountKey = "userPassword"

    // MARK: - Save
    func save(email: String, password: String, rememberMe: Bool) {
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)

        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.savePasswordToKeychain(password)
        }
    }

    // MARK: - Load
    func load(completion: @escaping (String?, String?, Bool) -> Void) {
        let email = UserDefaults.standard.string(forKey: emailKey)
        let rememberMe = UserDefaults.standard.bool(forKey: rememberMeKey)

        DispatchQueue.global(qos: .userInitiated).async {
            let password = self.loadPasswordFromKeychain()
            DispatchQueue.main.async {
                completion(email, password, rememberMe)
            }
        }
    }

    // MARK: - Remove
    func clear() {
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)

        DispatchQueue.global(qos: .background).async {
            _ = self.deletePasswordFromKeychain()
        }
    }

    func checkRememberMe() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }

    // MARK: - Keychain helpers
    @discardableResult
    private func savePasswordToKeychain(_ password: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passwordAccountKey
        ]

        // Remove existing password
        SecItemDelete(query as CFDictionary)

        // Add new password
        let addQuery: [String: Any] = query.merging([
            kSecValueData as String: passwordData
        ]) { _, new in new }

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func loadPasswordFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passwordAccountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return password
    }

    @discardableResult
    private func deletePasswordFromKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passwordAccountKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
