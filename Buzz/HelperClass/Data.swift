//
//  Data.swift
//  Broker Portal
//
//  Created by Pankaj on 23/04/25.
//

import Foundation

extension Data {
    func dataToDictionary() throws -> [String: Any] {
        let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
        guard let dict = jsonObject as? [String: Any] else {
            throw NSError(domain: "Invalid JSON format", code: 1001, userInfo: nil)
        }
        return dict
    }
}

extension Encodable {
    func toDictionary(usingSnakeCase: Bool = true) -> [String: Any]? {
        do {
            let encoder = JSONEncoder()
            if usingSnakeCase {
                encoder.keyEncodingStrategy = .convertToSnakeCase
            }

            // Encode the model to Data
            let data = try encoder.encode(self)

            // Decode to dictionary
            let rawObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard var dictionary = rawObject as? [String: Any] else {
                return nil
            }

            // Reflect on the object to find nil fields
            let mirror = Mirror(reflecting: self)

            for child in mirror.children {
                if let label = child.label {
                    let key = usingSnakeCase ? Self.convertToSnakeCase(label) : label
                    if child.value is OptionalProtocol, (child.value as? OptionalProtocol)?.isNil == true {
                        dictionary[key] = NSNull() // Add NSNull for nil fields
                    }
                }
            }

            return dictionary
        } catch {
            Log.debug("❌ Failed to convert to dictionary: \(error)")
            return nil
        }
    }

    // Convert camelCase to snake_case manually to match keyEncodingStrategy
    private static func convertToSnakeCase(_ input: String) -> String {
        var result = ""
        for character in input {
            if character.isUppercase {
                result += "_" + character.lowercased()
            } else {
                result += String(character)
            }
        }
        return result
    }
}

protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    var isNil: Bool {
        self == nil
    }
}
