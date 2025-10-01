//
//  CountryCodePicker.swift
//  
//
//  Created by Pankaj Rawat on 25/08/25.
//

struct Country: Decodable {
    let name: String?
    let code: String?
    let phoneCode: String?
    
    /// Emoji flag as String
    var flag: String? {
        guard let code = code else { return nil }
        return code.uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
    
    /// Emoji flag rendered as UIImage
    var flagImage: UIImage? {
        return flag?.emojiToImage(fontSize: 60)
    }
}



import Foundation
import UIKit

final class CountryManager {
    
    // Shared singleton instance
    static let shared = CountryManager()
    
    // Private init to prevent external creation
    private init() {}
    
    // Cached countries
    private var countries: [Country]?
    
    /// Load countries from JSON (cached after first load)
    func getCountries() -> [Country] {
        if let cached = countries {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            Log.debug("❌ countries.json not found")
            return []
        }
        
        do {
            let decoded = try JSONDecoder().decode([Country].self, from: data)
            countries = decoded
            return decoded
        } catch {
            print("❌ Failed to decode countries.json:", error)
            return []
        }
    }
    
    /// Get current device country (iOS 13+ safe)
    func getCurrentCountry() -> Country? {
        guard let regionCode = Locale.current.regionCode?.uppercased() else { return nil }
        return countries?.first { $0.code?.uppercased() == regionCode }
    }
    
    func getCountry(phoneCode: String) -> Country? {
        let normalizedInput = phoneCode.trimmingCharacters(in: .whitespacesAndNewlines)
                                       .replacingOccurrences(of: "+", with: "")
                                       .uppercased()

        return getCountries().first {
            $0.phoneCode?
                .replacingOccurrences(of: "+", with: "")
                .uppercased() == normalizedInput
        }
    }

}

extension String {
    func emojiToImage(fontSize: CGFloat = 40, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
            let font = UIFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            
            let size = (self as NSString).size(withAttributes: attributes)
            let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
            let image = renderer.image { _ in
                (self as NSString).draw(at: .zero, withAttributes: attributes)
            }
            return image
        }
}
