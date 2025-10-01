//
//  UIString.swift
//  Zupet
//
//  Created by Pankaj Rawat on 30/08/25.
//

import Foundation

extension String {
    func toUTC(
        inputFormat: DateFormatType,
        outputFormat: DateFormatType
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current  // input is local
        
        var inputString = self
        var inputFormatString = inputFormat.rawValue
        
        let now = Date()
        let calendar = Calendar.current
        
        // ✅ If input format doesn’t include month, add current month
        if !inputFormatString.contains("M") {
            let currentMonth = calendar.component(.month, from: now)
            inputString += " \(currentMonth)"
            inputFormatString += " MM"
        }
        
        // ✅ If input format doesn’t include year, add current year
        if !inputFormatString.contains("y") {
            let currentYear = calendar.component(.year, from: now)
            inputString += " \(currentYear)"
            inputFormatString += " yyyy"
        }
        
        // Parse local string into Date
        formatter.dateFormat = inputFormatString
        guard let date = formatter.date(from: inputString) else { return self }
        
        // Convert → UTC string
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = outputFormat.rawValue
        return formatter.string(from: date)
    }
    
    func toLocalTime(
        inputFormat: DateFormatType,
        outputFormat: DateFormatType
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC") // input is UTC
        
        // Parse UTC string into Date
        formatter.dateFormat = inputFormat.rawValue
        guard let date = formatter.date(from: self) else { return self }
        
        // Convert → Local string
        formatter.timeZone = .current
        formatter.dateFormat = outputFormat.rawValue
        return formatter.string(from: date)
    }
    
    func shortAge(fromFormat format: String = "yyyy-MM-dd") -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let dob = dateFormatter.date(from: self) else {
            return nil
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: dob, to: now)
        
        if let years = components.year, years >= 1 {
            return "\(years) yrs"
        } else if let months = components.month {
            return "\(months) m"
        }
        
        return nil
    }
    
    func isWithinTwoHours() -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: self) else {
            return false
        }
        
        let now = Date() // current local time
        let twoHoursLater = now.addingTimeInterval(2 * 60 * 60) // +2 hours
        
        // Check if cremation time is >= now AND <= 2 hours later
        return date >= now && date <= twoHoursLater
    }
    
    func toDateFromISO() -> Date? {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: self)
        }
}
