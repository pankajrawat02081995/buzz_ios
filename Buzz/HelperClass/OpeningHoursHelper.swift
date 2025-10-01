//
//  OpeningHoursHelper.swift
//  Zupet
//
//  Created by Pankaj Rawat on 07/09/25.
//

import UIKit

struct OpenCloseUI {
    let openText: String
    let openColor: UIColor
    let closeText: String
    let closeColor: UIColor
}

enum OpeningHoursHelper {
    private static let parseFormats = ["H:mm", "HH:mm", "h:mm a", "hh:mm a"]
    
    private static func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for f in parseFormats {
            formatter.dateFormat = f
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        return nil
    }
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a" // always show 12hr format with AM/PM
        return formatter.string(from: date)
    }
    
    static func status(openingTime: String?, closingTime: String?) -> OpenCloseUI {
        guard let openStr = openingTime?.trimmingCharacters(in: .whitespacesAndNewlines),
              let closeStr = closingTime?.trimmingCharacters(in: .whitespacesAndNewlines),
              let openDate = parseTime(openStr),
              let closeDate = parseTime(closeStr)
        else {
            return OpenCloseUI(openText: "Closed",
                               openColor: .red,
                               closeText: "Closed",
                               closeColor: .red)
        }
        
        let calendar = Calendar.current
        let openComp = calendar.dateComponents([.hour, .minute], from: openDate)
        let closeComp = calendar.dateComponents([.hour, .minute], from: closeDate)
        let now = Date()
        let nowComp = calendar.dateComponents([.hour, .minute], from: now)
        
        let openMinutes = (openComp.hour ?? 0) * 60 + (openComp.minute ?? 0)
        let closeMinutes = (closeComp.hour ?? 0) * 60 + (closeComp.minute ?? 0)
        let nowMinutes = (nowComp.hour ?? 0) * 60 + (nowComp.minute ?? 0)
        
        let isOpen: Bool
        if openMinutes <= closeMinutes {
            isOpen = (nowMinutes >= openMinutes && nowMinutes < closeMinutes)
        } else {
            // Overnight case
            isOpen = (nowMinutes >= openMinutes || nowMinutes < closeMinutes)
        }
        
        if isOpen {
            return OpenCloseUI(
                openText: "Open",
                openColor: .systemGreen,
                closeText: "Closes at \(formatTime(closeDate))",
                closeColor: .darkGray
            )
        } else {
            return OpenCloseUI(
                openText: "Opens at \(formatTime(openDate))",
                openColor: .darkGray,
                closeText: "Closed",
                closeColor: .red
            )
        }
    }
}
