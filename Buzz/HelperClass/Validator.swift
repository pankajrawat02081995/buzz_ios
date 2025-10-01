//
//  Validater.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import Foundation

public struct Validator {
    
    static func format(_ digits: String) -> String {
        let numbersOnly = String(digits.prefix(10))
        
        let areaCode = numbersOnly.prefix(3)
        let middle = numbersOnly.dropFirst(3).prefix(3)
        let last = numbersOnly.dropFirst(6)
        
        var formatted = ""
        
        // Always add opening parenthesis if any digits
        if !areaCode.isEmpty {
            formatted += "(" + areaCode
            // Only add closing ')' if area code is full and more digits exist
            if areaCode.count == 3 && !middle.isEmpty {
                formatted += ")"
            }
        }
        
        if !middle.isEmpty {
            formatted += " " + middle
        }
        
        if !last.isEmpty {
            formatted += " " + last
        }
        
        return formatted
    }
    
    // MARK: - Email Validation
    public static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Phone Number Validation (Basic)
//    public static func isValidPhone(_ phone: String) -> Bool {
//        let phoneRegex = #"^\d{10}$"#
//        return phone.range(of: phoneRegex, options: .regularExpression) != nil
//    }
    public static func isValidPhone(_ phone: String) -> Bool {
        // ✅ Allows:
        // - 10 digits (e.g. 9876543210)
        // - +91 followed by 10 digits
        // - +1 followed by 10 digits, etc.
        let phoneRegex = #"^(\+\d{1,3})?\d{10}$"#
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }

    
    // MARK: - Password Validation
    /// At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    public static func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?/~\\-]).{8,}$"#
        return password.range(of: passwordRegex, options: .regularExpression) != nil
    }
}
