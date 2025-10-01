//
//  UIDateFormate.swift
//  Broker Portal
//
//  Created by Pankaj on 05/05/25.
//

import Foundation
import UIKit

enum DateFormatType: String {
    case yyyyMMdd = "yyyy-MM-dd"
    case MMddyyyy = "MM-dd-yyyy"
    case ddMMyyyy = "dd-MM-yyyy"
    case ddd = "ddd"
    case HHmm = "HH:mm"
    case ddEEE = "dd EEE"
    case MMMddyyyy = "MMM dd, yyyy"
    case fullDateTime = "yyyy-MM-dd HH:mm:ss"
    case utcFormate = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    case localWithDate = "EEEE • dd MMM, yyyy"
    case localAppointmentTime = "dd EEEE hh:mm a"
    case custom // use only if you want to provide your own format string manually
}

struct DateUtils {
    static func convertDateFormat(
        dateString: String,
        inputFormat: DateFormatType,
        outputFormat: DateFormatType,
        customInputFormat: String? = nil,
        customOutputFormat: String? = nil
    ) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        inputFormatter.dateFormat = (inputFormat == .custom) ? (customInputFormat ?? "") : inputFormat.rawValue
        outputFormatter.dateFormat = (outputFormat == .custom) ? (customOutputFormat ?? "") : outputFormat.rawValue
        
        guard let date = inputFormatter.date(from: dateString) else {
            Log.debug("❌ Failed to parse date: \(dateString)")
            return nil
        }
        return outputFormatter.string(from: date)
    }
    
    /// Converts a date string to a Date object
    static func convertToDate(
        dateString: String,
        inputFormat: DateFormatType,
        customInputFormat: String? = nil
    ) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = (inputFormat == .custom) ? (customInputFormat ?? "") : inputFormat.rawValue
        
        guard let date = formatter.date(from: dateString) else {
            Log.error("❌ Failed to convert to Date: \(dateString)")
            return nil
        }
        
        return date
    }
}

