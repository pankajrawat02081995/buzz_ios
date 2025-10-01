//
//  DecodedUser.swift
//  Broker Portal
//
//  Created by Pankaj on 24/04/25.
//

import Foundation
import CommonCrypto

actor AESDecryptor {
    private static let key = "uQddB!NL$TmaKkmYRuu_S4RF3dM69ehj"
    private static let iv = "RvF2$T5dKGeT_CkC"

    static func decryptCBC(base64EncodedString: String) async -> String? {
        guard let encryptedData = Data(base64Encoded: base64EncodedString),
              let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else {
            Log.error("Invalid base64 input or key/IV conversion failed.")
            return nil
        }

        return encryptedData.withUnsafeBytes { encryptedBytes in
            keyData.withUnsafeBytes { keyBytes in
                ivData.withUnsafeBytes { ivBytes in
                    let bufferSize = encryptedData.count + kCCBlockSizeAES128
                    var outputData = Data(count: bufferSize)
                    var numBytesDecrypted = 0

                    let status = outputData.withUnsafeMutableBytes { outputBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyData.count,
                            ivBytes.baseAddress,
                            encryptedBytes.baseAddress, encryptedData.count,
                            outputBytes.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }

                    guard status == kCCSuccess else {
                        Log.error("Decryption failed with status: \(status)")
                        return nil
                    }

                    outputData.removeSubrange(numBytesDecrypted..<outputData.count)
                    return String(data: outputData, encoding: .utf8)
                }
            }
        }
    }
}

