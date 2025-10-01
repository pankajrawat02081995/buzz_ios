//
//  ErrorMessages.swift
//  Broker Portal
//
//  Created by Pankaj on 21/04/25.
//

import Foundation

enum Log {
    static func error(_ message: String, error: Error? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        var output = "\n🛑 🛑 🛑 🛑"
        output += "\nFile: \(file)"
        output += "\nFunction: \(function)"
        output += "\nLine: \(line)"
        output += "\nMessage: \(message)"
        if let error = error {
            output += "\nError: \(error)"
        }
        output += "\n🛑 🛑 🛑 🛑"
        debugPrint(output)
    }
    
    static func error(_ message: String) {
        debugPrint(message)
    }
    
    static func debug(_ message: Any) {
        debugPrint(message)
    }
}
