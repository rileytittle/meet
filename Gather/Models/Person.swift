import Foundation
import SwiftData

enum ReminderUnit: String, CaseIterable, Identifiable {
    case days, weeks, months

    var id: Self { self }

    var calendarComponent: Calendar.Component {
        switch self {
        case .days: .day
        case .weeks: .weekOfYear
        case .months: .month
        }
    }

    func label(count: Int) -> String {
        switch self {
        case .days: count == 1 ? "day" : "days"
        case .weeks: count == 1 ? "week" : "weeks"
        case .months: count == 1 ? "month" : "months"
        }
    }
}

@Model
final class Person {
    var name: String
    /// Identifier of the contact this person was added from, used to avoid duplicates.
    var contactIdentifier: String?
    /// Contact photo thumbnail, refreshed from Contacts on launch.
    @Attribute(.externalStorage) var photoData: Data? = nil
    /// How many `reminderUnit`s between reminders. 0 turns reminders off.
    /// Keeps its original name from when reminders were always in days, so existing data carries over;
    /// use `reminderEvery` in code.
    var reminderIntervalDays: Int
    var reminderUnitRaw: String = ReminderUnit.days.rawValue
    /// Optional date of the first reminder. Nil means "one interval after the person was added".
    var reminderStartDate: Date? = nil
    var lastMetAt: Date?
    var createdAt: Date
    /// Stable identifier for this person's pending notification.
    var reminderID: UUID

    @Relationship(deleteRule: .cascade, inverse: \PrayerRequest.person)
    var prayerRequests: [PrayerRequest] = []

    init(name: String, contactIdentifier: String? = nil, photoData: Data? = nil) {
        self.name = name
        self.contactIdentifier = contactIdentifier
        self.photoData = photoData
        self.reminderIntervalDays = 1
        self.reminderUnitRaw = ReminderUnit.months.rawValue
        self.lastMetAt = nil
        self.createdAt = .now
        self.reminderID = UUID()
    }

    var reminderEvery: Int {
        get { reminderIntervalDays }
        set { reminderIntervalDays = newValue }
    }

    var reminderUnit: ReminderUnit {
        get { ReminderUnit(rawValue: reminderUnitRaw) ?? .days }
        set { reminderUnitRaw = newValue.rawValue }
    }

    var remindersEnabled: Bool { reminderEvery > 0 }

    var frequencyDescription: String {
        guard remindersEnabled else { return "Off" }
        if reminderEvery == 1 { return "Every \(reminderUnit.label(count: 1))" }
        return "Every \(reminderEvery) \(reminderUnit.label(count: reminderEvery))"
    }

    /// When the next meeting is due:
    /// - the start date, if one is set and you haven't met since it;
    /// - otherwise one interval after you last met (or after the person was added).
    var nextMeetingDue: Date? {
        guard remindersEnabled else { return nil }
        if let start = reminderStartDate, lastMetAt.map({ $0 < start }) ?? true {
            return start
        }
        return Calendar.current.date(byAdding: reminderUnit.calendarComponent, value: reminderEvery, to: lastMetAt ?? createdAt)
    }

    var isDue: Bool {
        guard let nextMeetingDue else { return false }
        return nextMeetingDue <= .now
    }
}
