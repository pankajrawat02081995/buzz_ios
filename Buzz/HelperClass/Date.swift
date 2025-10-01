//
//  Date.swift
//  Zupet
//
//  Created by Pankaj Rawat on 02/09/25.
//

import Foundation

extension Date {
    func toLocalTimeString() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"   // 12-hour format with AM/PM
            formatter.locale = Locale.current  // respect user’s locale
            formatter.timeZone = TimeZone.current
            return formatter.string(from: self)
        }
    
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        if secondsAgo < 60 {
            return "Just now"
        } else if secondsAgo < 3600 {
            let minutes = secondsAgo / 60
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else if secondsAgo < 86400 {
            let hours = secondsAgo / 3600
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if secondsAgo < 604800 {
            let days = secondsAgo / 86400
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if secondsAgo < 2592000 {
            let weeks = secondsAgo / 604800
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if secondsAgo < 31536000 {
            let months = secondsAgo / 2592000
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else {
            let years = secondsAgo / 31536000
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
    }
}
