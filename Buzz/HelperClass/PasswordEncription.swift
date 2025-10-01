//
//  PasswordEncription.swift
//  Zupet
//
//  Created by Pankaj Rawat on 06/08/25.
//

//MARK: Use

//DispatchQueue.global(qos: .userInitiated).async {
//    do {
//        let encrypted = try CryptoUtils.encryptCBC("Hello Swift!")
//        Log.debug("Encrypted: \(encrypted)")
//
//        let decrypted = try CryptoUtils.decryptCBC(encrypted)
//        Log.debug("Decrypted: \(decrypted)")
//    } catch {
//        Log.debug("Crypto error: \(error)")
//    }
//}


import Foundation
import CommonCrypto

enum CryptoError: Error {
    case keyLengthError
    case ivLengthError
    case encryptionFailed
    case decryptionFailed
    case base64DecodeError
}

struct CryptoUtils {
    private static let algorithm = CCAlgorithm(kCCAlgorithmAES)
    private static let options = CCOptions(kCCOptionPKCS7Padding)
    
    // Ensure 32-byte key and 16-byte IV
    private static let secretKey = "7f182f9014832ecd0421bdd6acc6b9a4629A568b"
    private static let secretIV = "Xy4@q9!eLs#1Vp$M"

    // MARK: - Public API
    
    static func encryptCBC(_ value: String) throws -> String {
        guard let keyData = secretKey.data(using: .utf8), [16, 24, 32].contains(keyData.count) else {
            throw CryptoError.keyLengthError
        }

        guard let ivData = secretIV.data(using: .utf8), ivData.count == kCCBlockSizeAES128 else {
            throw CryptoError.ivLengthError
        }

        guard let dataToEncrypt = value.data(using: .utf8) else {
            throw CryptoError.encryptionFailed
        }

        let encryptedData = try crypt(input: dataToEncrypt, keyData: keyData, ivData: ivData, operation: CCOperation(kCCEncrypt))
        return encryptedData.base64EncodedString()
    }

    static func decryptCBC(_ base64Encoded: String) throws -> String {
        guard let keyData = secretKey.data(using: .utf8), [16, 24, 32].contains(keyData.count) else {
            throw CryptoError.keyLengthError
        }

        guard let ivData = secretIV.data(using: .utf8), ivData.count == kCCBlockSizeAES128 else {
            throw CryptoError.ivLengthError
        }

        guard let dataToDecrypt = Data(base64Encoded: base64Encoded) else {
            throw CryptoError.base64DecodeError
        }

        let decryptedData = try crypt(input: dataToDecrypt, keyData: keyData, ivData: ivData, operation: CCOperation(kCCDecrypt))
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }

        return decryptedString
    }

    // MARK: - Internal AES Crypt function
    
    private static func crypt(input: Data, keyData: Data, ivData: Data, operation: CCOperation) throws -> Data {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)

        let status = input.withUnsafeBytes { inputBytes in
            keyData.withUnsafeBytes { keyBytes in
                ivData.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        operation,
                        algorithm,
                        options,
                        keyBytes.baseAddress, keyData.count,
                        ivBytes.baseAddress,
                        inputBytes.baseAddress, input.count,
                        &outBytes, outBytes.count,
                        &outLength
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw operation == CCOperation(kCCEncrypt) ? CryptoError.encryptionFailed : CryptoError.decryptionFailed
        }

        return Data(bytes: outBytes, count: outLength)
    }
}
