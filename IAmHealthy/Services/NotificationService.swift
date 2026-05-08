import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private let identifier = "weight.reminder"

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Schedule a reminder according to the user's chosen frequency.
    /// - Parameters:
    ///   - frequency: daily, weekly, or custom-days.
    ///   - time: a Date carrying the desired hour-and-minute components.
    ///   - weekday: Calendar weekday (1 = Sunday … 7 = Saturday); only used for `.weekly`.
    ///   - intervalDays: only used for `.custom`. Clamped to >= 1.
    func schedule(frequency: ReminderFrequency,
                  time: Date,
                  weekday: Int,
                  intervalDays: Int) async {
        cancel()
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = "Time to weigh in"
        content.body = "Log today's weight in I Am Healthy!"
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch frequency {
        case .daily:
            trigger = UNCalendarNotificationTrigger(dateMatching: hm, repeats: true)
        case .weekly:
            var comps = hm
            comps.weekday = max(1, min(7, weekday))
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .custom:
            let days = max(1, intervalDays)
            let interval = TimeInterval(days) * 86_400
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
        Analytics.signal(Analytics.Event.reminderScheduled, parameters: [
            "frequency": frequency.rawValue
        ])
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
