import Foundation
import SwiftData

/// A meeting scheduled with a person, optionally also added to the iPhone calendar.
@Model
final class Meeting {
    var title: String
    var date: Date
    var durationMinutes: Int
    /// Place name shown in the app (a map place's name, or whatever was typed).
    var location: String?
    var locationAddress: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var person: Person?
    /// Identifier of the event added to the iPhone calendar, if one was added.
    var calendarEventID: String?
    var createdAt: Date

    init(title: String, date: Date, durationMinutes: Int = 60, location: String? = nil) {
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.location = location
        self.createdAt = .now
    }

    var endDate: Date {
        date.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    /// Hasn't finished yet.
    var isUpcoming: Bool { endDate >= .now }

    var place: MeetingPlace? {
        get {
            guard let location else { return nil }
            return MeetingPlace(name: location, address: locationAddress, latitude: latitude, longitude: longitude)
        }
        set {
            location = newValue?.name
            locationAddress = newValue?.address
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }
}
