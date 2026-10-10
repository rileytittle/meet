import Foundation
import SwiftData

@Model
final class Person {
    var name: String
    /// Identifier of the contact this person was added from, used to avoid duplicates.
    var contactIdentifier: String?
    /// How often to be reminded to meet, in days. 0 turns reminders off.
    var reminderIntervalDays: Int
    var lastMetAt: Date?
    var createdAt: Date
    /// Stable identifier for this person's pending notification.
    var reminderID: UUID

    @Relationship(deleteRule: .cascade, inverse: \PrayerRequest.person)
    var prayerRequests: [PrayerRequest] = []

    init(name: String, contactIdentifier: String? = nil, reminderIntervalDays: Int = 30) {
        self.name = name
        self.contactIdentifier = contactIdentifier
        self.reminderIntervalDays = reminderIntervalDays
        self.lastMetAt = nil
        self.createdAt = .now
        self.reminderID = UUID()
    }

    /// When the next meeting is due, counted from the last meeting (or from when the person was added).
    var nextMeetingDue: Date? {
        guard reminderIntervalDays > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: reminderIntervalDays, to: lastMetAt ?? createdAt)
    }

    var isDue: Bool {
        guard let nextMeetingDue else { return false }
        return nextMeetingDue <= .now
    }
}
