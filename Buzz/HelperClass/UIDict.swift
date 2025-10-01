//
//  UIDict.swift
//  Broker Portal
//
//  Created by Pankaj on 23/04/25.
//

import Foundation

extension Dictionary where Key == String {
    func data() async throws -> Data {
        return try await APIManagerHelper.shared.convertIntoData(from: self)
    }
}
