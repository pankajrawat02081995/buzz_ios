//
//  CalenderHelper.swift
//  Zupet
//
//  Created by Pankaj Rawat on 02/09/25.
//

//import Foundation
//
//// MARK: - Model
//struct DayModel {
//    let day: String
//    let date: String
//    let isWeekend: Bool
//}
//
//// MARK: - Calendar Utility
//final class CalendarHelper {
//    
//    static func generateDaysInfo(
//        from weekdayDescriptions: [String],
//        numberOfDays: Int
//    ) -> [DayModel] {
//        var result: [DayModel] = []
//        let calendar = Calendar.current
//        let today = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd" // ISO format for return
//        
//        let weekdayFormatter = DateFormatter()
//        weekdayFormatter.dateFormat = "EEE" // Monday, Tuesday...
//        
//        for i in 0..<numberOfDays {
//            if let date = calendar.date(byAdding: .day, value: i, to: today) {
//                let dayName = weekdayFormatter.string(from: date)
//                let dateString = dateFormatter.string(from: date)
//                
//                // Check if this day exists in your weekdayDescriptions
//                let isAvailable = weekdayDescriptions.contains { $0.hasPrefix(dayName) }
//                
//                // Weekend logic (for now only Sunday)
//                let isWeekend = (dayName == "Sunday")
//                
//                if isAvailable {
//                    let info = DayModel(day: dayName, date: dateString, isWeekend: isWeekend)
//                    result.append(info)
//                }
//            }
//        }
//        
//        return result
//    }
//    static func generateDays(for month: Int? = nil, year: Int? = nil) -> [DayModel] {
//        var days: [DayModel] = []
//        
//        let calendar = Calendar.current
//        let today = Date()
//        
//        // Current components
//        let currentComponents = calendar.dateComponents([.year, .month, .day], from: today)
//        guard let currentYear = currentComponents.year,
//              let currentMonth = currentComponents.month,
//              let currentDay = currentComponents.day else { return days }
//        
//        // If user didn’t pass → default to today’s month/year
//        let selectedYear = year ?? currentYear
//        let selectedMonth = month ?? currentMonth
//        
//        // Handle past months (don’t allow)
//        if selectedYear < currentYear || (selectedYear == currentYear && selectedMonth < currentMonth) {
//            return []
//        }
//        
//        // Start day logic
//        let startDay = (selectedYear == currentYear && selectedMonth == currentMonth) ? currentDay : 1
//        
//        // Build start date
//        var components = DateComponents(year: selectedYear, month: selectedMonth, day: startDay)
//        guard let startDate = calendar.date(from: components) else { return [] }
//        
//        // Number of days in month
//        guard let range = calendar.range(of: .day, in: .month, for: startDate) else { return [] }
//        let totalDays = range.count
//        
//        for day in startDay...totalDays {
//            components.day = day
//            if let date = calendar.date(from: components) {
//                let weekdayIndex = calendar.component(.weekday, from: date) // Sunday = 1
//                let formatter = DateFormatter()
//                formatter.dateFormat = "EEE" // full day name
//                
//                let model = DayModel(
//                    day: formatter.string(from: date),
//                    date: "\(day)",
//                    isWeekend: weekdayIndex == 1
//                )
//                days.append(model)
//            }
//        }
//        
//        return days
//    }
//}


import Foundation

// MARK: - Models
public struct Slot {
    public let slotTime: String    // display like "10:00 AM"
    public let isAvailable: Bool   // true if slot start >= now (local)
    public init(slotTime: String, isAvailable: Bool) {
        self.slotTime = slotTime; self.isAvailable = isAvailable
    }
}

public struct DaySlot {
    public let day: String         // "Tuesday"
    public let date: String        // "2" (day of month, local)
    public let isClosed: Bool
    public let slots: [Slot]
    public init(day: String, date: String, isClosed: Bool, slots: [Slot]) {
        self.day = day; self.date = date; self.isClosed = isClosed; self.slots = slots
    }
}

// MARK: - Slot Generator
public final class SlotGenerator {
    
    /// Generate DaySlot objects for `days` days starting from today.
    /// - weekdayDescriptions: array of 7 strings (usually Mon→Sun) like "Tuesday: 9:00 AM – 5:30 PM"
    /// - days: how many days from today (default 7)
    /// - slotMinutes: size of slot in minutes (default 30)
    /// - includePastSlotsForToday: if true, past slots will have isAvailable = false but still returned (we always return them)
    public static func generateSlots(
        weekdayDescriptions: [String],
        days: Int = 7,
        slotMinutes: Int = 30,
        includePastSlotsForToday: Bool = true,
        calendar: Calendar = .current
    ) -> [DaySlot] {
        guard days > 0 else { return [] }
        let today = Date()
        // normalize and build quick lookup by day-name prefix (e.g. "tuesday" -> "9:00 AM - 5:30 PM")
        let normalizedLines = weekdayDescriptions.map { normalizeLine($0) }
        
        // Prepare formatters
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale.current
        weekdayFormatter.calendar = calendar
        weekdayFormatter.dateFormat = "EEEE" // "Tuesday"
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale.current
        displayFormatter.calendar = calendar
        displayFormatter.dateFormat = "h:mm a" // slot display
        
        var output: [DaySlot] = []
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayName = weekdayFormatter.string(from: date) // e.g. "Tuesday"
            _ = dayName.lowercased()
            let dateStr = String(calendar.component(.day, from: date))
            
            // find line by day name prefix (case-insensitive). fallback to google index mapping if not found.
            let line = findLine(for: date, inNormalizedLines: normalizedLines, calendar: calendar, weekdayFormatter: weekdayFormatter)
            // extract part after first colon
            let timePart = extractTimePart(from: line)
            
            // determine closed/open/24h/multiple ranges
            var daySlots: [Slot] = []
            var isClosed = false
            
            if timePart.isEmpty || timePart.lowercased().contains("closed") {
                isClosed = true
            } else if timePart.lowercased().contains("open 24") || timePart.lowercased().contains("24 hours") {
                // full day 00:00 - 24:00 (till next day's midnight)
                if let startOfDay = calendar.startOfDay(for: date) as Date?,
                   let startNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
                    daySlots.append(contentsOf:
                        makeSlotsBetween(startDate: startOfDay, endDate: startNextDay, stepMinutes: slotMinutes, displayFormatter: displayFormatter, calendar: calendar)
                    )
                }
            } else {
                // split multiple ranges by comma
                let rangeStrings = splitRanges(timePart)
                // for each range parse start and end into Date anchored to this date (handle overnight)
                for rangeStr in rangeStrings {
                    guard let (startDate, endDate) = parseRange(rangeStr, anchoredTo: date, calendar: calendar) else { continue }
                    
                    if startDate < endDate {
                        // normal or same-day range
                        daySlots.append(contentsOf: makeSlotsBetween(startDate: startDate, endDate: endDate, stepMinutes: slotMinutes, displayFormatter: displayFormatter, calendar: calendar))
                    } else {
                        // if for any reason endDate <= startDate (shouldn't after parseRange), skip
                    }
                }
            }
            
            // mark availability based on now: slotStart >= now => available
            let now = Date()
            let finalSlots = daySlots.map { slot -> Slot in
                // parse slot.slotTime back to a Date on this `date` to compare -> but we already constructed slots with Date-based generator;
                // so our makeSlotsBetween returns Strings only - we'll recreate isAvailable using displayFormatter + date anchors
                // To avoid double parsing, we change makeSlotsBetween to return (Date, String) pairs. For now, we compute isAvailable by reconstructing Date from display string.
                // Reconstruct:
                if let slotDate = parseDisplayStringToDate(slot.slotTime, on: date, calendar: calendar, displayFormatter: displayFormatter) {
                    let isAvail = includePastSlotsForToday ? (slotDate >= now) : (slotDate >= now) // always return slot, availability computed same way
                    return Slot(slotTime: slot.slotTime, isAvailable: isAvail)
                } else {
                    // fallback: mark available if date is in future
                    return Slot(slotTime: slot.slotTime, isAvailable: date >= calendar.startOfDay(for: now))
                }
            }
            
            output.append(DaySlot(day: dayName, date: dateStr, isClosed: isClosed, slots: finalSlots))
        }
        
        return output
    }
    
    // MARK: - Helpers
    
    // Normalize a Google line: replace weird spaces/dashes and trim
    private static func normalizeLine(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace various unicode spaces/dashes
        let replacements: [(String,String)] = [
            ("\u{00A0}", " "), ("\u{202F}", " "), ("\u{2009}", " "), (" ", " "),
            ("–", "-"), ("—", "-"), ("-", "-")
        ]
        for (from, to) in replacements { s = s.replacingOccurrences(of: from, with: to) }
        return s
    }
    
    // Extract substring after the first colon (":")
    private static func extractTimePart(from normalizedLine: String) -> String {
        let parts = normalizedLine.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.count == 2 ? parts[1] : ""
    }
    
    // Split ranges safely by comma (but ignore commas inside weird contexts — simple split is OK for Google format)
    private static func splitRanges(_ timePart: String) -> [String] {
        return timePart.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    // Parse "START - END" into Date anchored to `date`. Returns (startDate, endDate) where endDate may be next day if needed.
    // Accepts times like "9:00 AM", "21:30", "24:00", "10 AM", etc.
    private static func parseRange(_ rangeStr: String, anchoredTo date: Date, calendar: Calendar) -> (Date, Date)? {
        // normalize hyphen char
        let r = rangeStr.replacingOccurrences(of: " - ", with: "-").replacingOccurrences(of: " -", with: "-").replacingOccurrences(of: "- ", with: "-")
        let parts = r.split(separator: "-", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2 else { return nil }
        let startToken = parts[0]
        let endToken = parts[1]
        
        guard let startDate = parseTimeToDate(startToken, onDay: date, calendar: calendar),
              var endDate = parseTimeToDate(endToken, onDay: date, calendar: calendar) else {
            return nil
        }
        // If end <= start, it's overnight => push end to next day
        if endDate <= startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }
        return (startDate, endDate)
    }
    
    // Parse a time token into Date anchored to specific day.
    private static func parseTimeToDate(_ token: String, onDay day: Date, calendar: Calendar) -> Date? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        // Accept "24:00" specially -> next day's midnight
        if trimmed == "24:00" {
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day))
            return startOfNextDay
        }
        // Try multiple formats with en_US_POSIX to reliably parse am/pm
        let formats = ["h:mm a","hh:mm a","h a","H:mm","HH:mm","HH:mm:ss"]
        for fmt in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.calendar = calendar
            df.dateFormat = fmt
            if let parsed = df.date(from: trimmed) {
                // extract hour/minute and put onto `day`
                let comps = calendar.dateComponents([.hour, .minute], from: parsed)
                var dayComps = calendar.dateComponents([.year, .month, .day], from: day)
                dayComps.hour = comps.hour
                dayComps.minute = comps.minute
                dayComps.second = 0
                if let final = calendar.date(from: dayComps) {
                    return final
                }
            }
        }
        // As a last attempt, try current-locale "h:mm a" parse
        let df2 = DateFormatter()
        df2.locale = Locale.current
        df2.calendar = calendar
        df2.dateFormat = "h:mm a"
        if let parsed = df2.date(from: trimmed) {
            let comps = calendar.dateComponents([.hour, .minute], from: parsed)
            var dayComps = calendar.dateComponents([.year, .month, .day], from: day)
            dayComps.hour = comps.hour
            dayComps.minute = comps.minute
            dayComps.second = 0
            return calendar.date(from: dayComps)
        }
        return nil
    }
    
    // Generate slots between two Date bounds (startDate inclusive, endDate exclusive). Returns Slot objects with display time and availability left as placeholder strings (availability computed later).
    private static func makeSlotsBetween(startDate: Date, endDate: Date, stepMinutes: Int, displayFormatter: DateFormatter, calendar: Calendar) -> [Slot] {
        guard startDate < endDate, stepMinutes > 0 else { return [] }
        var result: [Slot] = []
        var cur = startDate
        let now = Date()
        while cur < endDate {
            let display = displayFormatter.string(from: cur)
            // isAvailable true if the slot start is >= now
            let isAvail = cur >= now
            result.append(Slot(slotTime: display, isAvailable: isAvail))
            guard let next = calendar.date(byAdding: .minute, value: stepMinutes, to: cur) else { break }
            cur = next
        }
        return result
    }
    
    // Find the correct line for a date. Prefer direct day-name match; otherwise fallback to Google index mapping (Mon=0..Sun=6).
    private static func findLine(for date: Date, inNormalizedLines lines: [String], calendar: Calendar, weekdayFormatter: DateFormatter) -> String {
        let dayName = weekdayFormatter.string(from: date).lowercased()
        if let byName = lines.first(where: { $0.lowercased().starts(with: dayName + ":") || $0.lowercased().starts(with: dayName + " :") || $0.lowercased().starts(with: dayName) }) {
            return byName
        }
        // fallback to google index mapping Mon=0..Sun=6
        let appleWeekday = calendar.component(.weekday, from: date) // 1 = Sun ... 7 = Sat
        let googleIndex = (appleWeekday + 5) % 7 // Mon=0
        if googleIndex < lines.count {
            return lines[googleIndex]
        }
        return lines.first ?? ""
    }
    
    // Recreate a Date from a display string ("10:00 AM") on the given date (used only if needed)
    private static func parseDisplayStringToDate(_ display: String, on date: Date, calendar: Calendar, displayFormatter: DateFormatter) -> Date? {
        if let parsed = displayFormatter.date(from: display) {
            let comps = calendar.dateComponents([.hour, .minute], from: parsed)
            var dayComps = calendar.dateComponents([.year, .month, .day], from: date)
            dayComps.hour = comps.hour
            dayComps.minute = comps.minute
            dayComps.second = 0
            return calendar.date(from: dayComps)
        }
        return nil
    }
}
