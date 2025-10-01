//
//  AlarmManager.swift
//  Robust Alarm Manager
//
//  Created by Pankaj on 2025-09-21
//

import Foundation
import UserNotifications
import AVFoundation
import AudioToolbox

// MARK: - Weekday Enum
enum Weekday: Int, CaseIterable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var calendarValue: Int { rawValue } // Matches Calendar.weekday (1 = Sunday)
}

// MARK: - Alarm Model
struct Alarm: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var time: Date
    var repeatDays: [Weekday]
    var ringtoneName: String // without extension
    var vibration: Bool
    var snoozeEnabled: Bool
    var isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        time: Date,
        title: String,
        repeatDays: [Weekday] = [],
        ringtoneName: String = "default",
        vibration: Bool = true,
        snoozeEnabled: Bool = true,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.repeatDays = repeatDays
        self.ringtoneName = ringtoneName
        self.vibration = vibration
        self.snoozeEnabled = snoozeEnabled
        self.isEnabled = isEnabled
    }

    var repeatDaysText: String {
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays.isEmpty { return "Never" }
        return repeatDays.map { $0.shortName }.joined(separator: ", ")
    }
}

// MARK: - Alarm Manager
final class AlarmManager: NSObject {
    static let shared = AlarmManager()

    // Persistence key
    private let storageKey = "savedAlarms"

    // In-memory store
    private var alarms: [Alarm] = []

    // Audio player for in-app ringing
    private var player: AVAudioPlayer?
    private(set) var isRinging = false
    private var currentlyRingingAlarmId: String?

    private override init() {
        super.init()
        loadAlarms()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Public Helpers

    /// Call at app launch to request notification permission
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            completion?(granted)
        }
    }

    func getAlarms() -> [Alarm] { alarms }

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        // Schedule only if enabled
        if alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }

    func updateAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        // Cancel existing notifications first (prevents duplicates)
        cancelNotificationsForAlarm(alarmID: alarm.id)
        alarms[index] = alarm
        saveAlarms()
        if alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }

    func deleteAlarm(_ id: String) {
        // Remove from memory & persistence
        alarms.removeAll { $0.id == id }
        saveAlarms()
        // Cancel any pending/delivered notifications
        cancelNotificationsForAlarm(alarmID: id)
        // If currently ringing, stop if it's the same
        if currentlyRingingAlarmId == id {
            stopAlarmSound()
        }
    }

    /// Enable or disable an alarm
    func setAlarmEnabled(id: String, isEnabled: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isEnabled = isEnabled
        saveAlarms()
        if isEnabled {
            scheduleAlarm(alarms[index])
        } else {
            cancelNotificationsForAlarm(alarmID: id)
            if currentlyRingingAlarmId == id { stopAlarmSound() }
        }
    }

    // Snooze helper — schedules a one-off snooze and returns identifier used
    @discardableResult
    func snoozeAlarm(_ alarm: Alarm, minutes: Int = 5) -> String {
        stopAlarmSound()
        guard alarm.snoozeEnabled else { return "" }

        let snoozeId = "\(alarm.id)_snooze_\(Int(Date().timeIntervalSince1970))"
        let content = UNMutableNotificationContent()
        content.title = alarm.title + " (Snoozed)"
        content.body = "⏰ Snoozed alarm"
        content.sound = soundForAlarm(named: alarm.ringtoneName)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        addNotificationRequest(id: snoozeId, content: content, trigger: trigger)
        return snoozeId
    }

    // MARK: - Persistence
    private func saveAlarms() {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            Log.debug("AlarmManager: failed to encode alarms: \(error)")
        }
    }

    private func loadAlarms() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Alarm].self, from: data)
        else { return }
        alarms = decoded
    }

    // MARK: - Scheduling

    /// Schedules notifications for the given alarm. Will cancel any previously scheduled notifications for that alarm first.
    private func scheduleAlarm(_ alarm: Alarm) {
        // Ensure enabled
        guard alarm.isEnabled else { return }

        // First cancel any previous notifications for this alarm (to avoid duplicates after update)
        cancelNotificationsForAlarm(alarmID: alarm.id)

        // Prepare content
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "⏰ Your reminder is ringing"
        content.sound = soundForAlarm(named: alarm.ringtoneName)

        let center = UNUserNotificationCenter.current()

        if alarm.repeatDays.isEmpty {
            // Non-repeating daily/time once — schedule next occurrence as non-repeating if in past schedule for next day
            let dateComponents = dateComponentsForNextOccurrence(time: alarm.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            addNotificationRequest(id: alarm.id, content: content, trigger: trigger)
        } else {
            // For repeat days schedule a repeating trigger per weekday.
            for day in alarm.repeatDays {
                var components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
                components.weekday = day.calendarValue
                // repeating weekly
                let idForDay = "\(alarm.id)_\(day.rawValue)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                addNotificationRequest(id: idForDay, content: content, trigger: trigger)
            }
        }

        // Optionally: update delivered/pending badge or internal tracking here
        center.getPendingNotificationRequests { _ in /* nothing for now */ }
    }

    /// Determine date components for the next non-repeating firing of provided time (if time already passed today, schedule for tomorrow)
    private func dateComponentsForNextOccurrence(time: Date) -> DateComponents {
        let calendar = Calendar.current
        let now = Date()

        // Extract hour/minute from the alarm time
        var components = calendar.dateComponents([.hour, .minute], from: time)

        // Build a candidate date today with those hour/minute
        var proposed = calendar.date(bySettingHour: components.hour ?? 0,
                                     minute: components.minute ?? 0,
                                     second: 0,
                                     of: now) ?? now

        // If it's earlier than now, schedule for tomorrow
        if proposed <= now {
            proposed = calendar.date(byAdding: .day, value: 1, to: proposed) ?? proposed
        }

        let result = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: proposed)
        return result
    }

    // MARK: - Notification helpers

    private func addNotificationRequest(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.debug("AlarmManager: failed to add notification \(id): \(error)")
            } else {
                // debug:
                // print("Scheduled notification \(id)")
            }
        }
    }

    /// Cancel all pending/delivered notifications for an alarm (including its per-day and snooze identifiers)
    private func cancelNotificationsForAlarm(alarmID: String) {
        // IDS to remove:
        var identifiersToRemove: [String] = []

        // base id
        identifiersToRemove.append(alarmID)

        // weekly per-day ids
        for d in Weekday.allCases {
            identifiersToRemove.append("\(alarmID)_\(d.rawValue)")
        }

        // delivered/pending snooze pattern — since snoozes may contain timestamps, remove any delivered/pending notifications that start with alarmID + "_snooze" or contain it.
        // UNUserNotificationCenter does not provide wildcard removal, so we will fetch all pending/delivered IDs and filter.
        let center = UNUserNotificationCenter.current()

        // Remove exact generated identifiers
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        center.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)

        // Additionally remove any pending/delivered requests that start with alarmID + "_snooze" or contain alarm id (to catch previously created snoozes)
        center.getPendingNotificationRequests { requests in
            let toRemove = requests.compactMap { req -> String? in
                if req.identifier.hasPrefix("\(alarmID)_snooze") || req.identifier.contains("\(alarmID)_snooze") || req.identifier.contains("\(alarmID)_") && req.identifier.contains("_snooze") {
                    return req.identifier
                }
                // also remove any lingering other generated ids for this alarm
                if req.identifier.contains(alarmID) { return req.identifier }
                return nil
            }
            if !toRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: Array(Set(toRemove)))
            }
        }
        center.getDeliveredNotifications { delivered in
            let toRemove = delivered.compactMap { $0.request.identifier.contains(alarmID) ? $0.request.identifier : nil }
            if !toRemove.isEmpty {
                center.removeDeliveredNotifications(withIdentifiers: Array(Set(toRemove)))
            }
        }
    }

    // Choose a UNNotificationSound; if custom missing, fall back to default
    private func soundForAlarm(named soundName: String) -> UNNotificationSound {
        // Try wav then mp3; if not found, return default
        if Bundle.main.url(forResource: soundName, withExtension: "wav") != nil {
            return UNNotificationSound(named: UNNotificationSoundName("\(soundName).wav"))
        }
        if Bundle.main.url(forResource: soundName, withExtension: "mp3") != nil {
            return UNNotificationSound(named: UNNotificationSoundName("\(soundName).mp3"))
        }
        return .default
    }

    // MARK: - Sound & Vibration for in-app ringing

    /// Attempt to play alarm audio while app is foreground (or when user taps a notification). This is separate from the system notification sound.
    func playAlarmSound(ringtone: String, vibration: Bool, alarmId: String) {
        stopAlarmSound()

        // Keep track of which alarm is ringing
        currentlyRingingAlarmId = alarmId

        // Attempt to find audio file
        var url: URL? = nil
        if let u = Bundle.main.url(forResource: ringtone, withExtension: "wav") { url = u }
        else if let u = Bundle.main.url(forResource: ringtone, withExtension: "mp3") { url = u }

        guard let fileURL = url else {
            Log.debug("AlarmManager: audio file not found for \(ringtone) — falling back to system sound")
            // We can still vibrate once to indicate
            if vibration {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            isRinging = true
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()
            isRinging = true
            if vibration {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } catch {
            Log.debug("AlarmManager: error playing sound: \(error)")
        }
    }

    func stopAlarmSound() {
        player?.stop()
        player = nil
        isRinging = false
        currentlyRingingAlarmId = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Utilities for UI / debug

    /// Force reschedule all enabled alarms (useful on app update or settings change)
    func rescheduleAll() {
        // cancel everything first
        for a in alarms {
            cancelNotificationsForAlarm(alarmID: a.id)
        }
        // schedule only enabled
        for a in alarms where a.isEnabled {
            scheduleAlarm(a)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AlarmManager: UNUserNotificationCenterDelegate {

    // When a notification arrives while the app is foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        // Stop any previous ringing (avoid overlaps)
        if isRinging { stopAlarmSound() }

        // Extract base alarm id (strip _<day> or _snooze_... etc)
        let rawId = notification.request.identifier
        let baseId = baseAlarmId(from: rawId)

        if let alarm = alarms.first(where: { $0.id == baseId }) {
            // Play in-app sound and vibrate according to alarm settings
            playAlarmSound(ringtone: alarm.ringtoneName, vibration: alarm.vibration, alarmId: alarm.id)
        } else {
            // No matching alarm in memory — still potentially play default vibration
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        // Show banner + play system sound (system will play the UNNotificationSound attached)
        completionHandler([.banner, .list, .sound])
    }

    // When user taps a notification (app may be background or terminated)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let rawId = response.notification.request.identifier
        let baseId = baseAlarmId(from: rawId)

        if let alarm = alarms.first(where: { $0.id == baseId }) {
            // Play in-app sound now (user tapped)
            playAlarmSound(ringtone: alarm.ringtoneName, vibration: alarm.vibration, alarmId: alarm.id)
        } else {
            // Nothing found — do nothing
        }

        completionHandler()
    }

    // Helper to extract base alarm id from notification identifier
    private func baseAlarmId(from identifier: String) -> String {
        // The identifier format we use:
        // - "<alarmId>" for single, non-repeat (one-off)
        // - "<alarmId>_<weekdayNumber>" for repeating (e.g., alarmId_2)
        // - "<alarmId>_snooze_<timestamp>" for snoozes
        // So we extract the first component before the first underscore as base id only if the base id itself doesn't contain underscores.
        // But since alarm.id is a UUID we created (no underscores), it's safe to split by "_" and take first portion.
        if identifier.contains("_") {
            return String(identifier.split(separator: "_", maxSplits: 1, omittingEmptySubsequences: true).first ?? "")
        }
        return identifier
    }
}
