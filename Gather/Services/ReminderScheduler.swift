import Foundation
import UserNotifications

/// Schedules one local notification per person for when their next meeting is due.
enum ReminderScheduler {
    /// Hour of the day (local time) reminders are delivered.
    static let reminderHour = 9

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
    }

    /// Replaces any pending reminder for `person` with one for their next due date.
    /// Overdue people get a reminder the next morning, so calling this on launch keeps nudging until they're marked as met.
    static func schedule(for person: Person) {
        let center = UNUserNotificationCenter.current()
        let identifier = person.reminderID.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let due = person.nextMeetingDue else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to meet with \(person.name)"
        content.body = "It's been a while. Reach out and schedule a time to connect."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDateComponents(for: due), repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel(for person: Person) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [person.reminderID.uuidString])
    }

    private static func fireDateComponents(for due: Date) -> DateComponents {
        let calendar = Calendar.current
        let day = max(due, .now)
        var fireDate = calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: day) ?? day
        if fireDate <= .now {
            fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
    }
}
