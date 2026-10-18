import Foundation
import CoreLocation
import EventKit

/// Adds, updates, and removes meetings on the user's calendar.
///
/// Adding only asks for permission to add events. Updating or removing an event Gather added
/// needs full access, which is asked for the first time the user edits or deletes one.
enum CalendarService {
    private static let store = EKEventStore()

    struct EventDetails {
        var title: String
        var start: Date
        var end: Date
        var place: MeetingPlace?

        init(_ meeting: Meeting) {
            title = meeting.title
            start = meeting.date
            end = meeting.endDate
            place = meeting.place
        }
    }

    enum CalendarError: LocalizedError {
        case addAccessDenied
        case fullAccessDenied
        case noCalendar

        var errorDescription: String? {
            switch self {
            case .addAccessDenied:
                "Gather doesn't have permission to add events. You can allow it in Settings → Gather → Calendars."
            case .fullAccessDenied:
                "To change or remove events it added, Gather needs full calendar access. You can allow it in Settings → Gather → Calendars."
            case .noCalendar:
                "There's no calendar set up on this iPhone to add the event to."
            }
        }
    }

    /// Adds an event to the default calendar and returns its identifier.
    static func addEvent(_ details: EventDetails) async throws -> String? {
        guard try await store.requestWriteOnlyAccessToEvents() else {
            throw CalendarError.addAccessDenied
        }
        return try saveNewEvent(details)
    }

    /// Updates the event Gather added earlier and returns its identifier.
    /// If the event was deleted in the Calendar app, a new one is added instead.
    static func updateEvent(id: String, with details: EventDetails) async throws -> String? {
        try await requestFullAccess()
        guard let event = store.event(withIdentifier: id) else {
            return try saveNewEvent(details)
        }
        apply(details, to: event)
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    /// Removes the event Gather added earlier. Does nothing if it's already gone.
    static func removeEvent(id: String) async throws {
        try await requestFullAccess()
        guard let event = store.event(withIdentifier: id) else { return }
        try store.remove(event, span: .thisEvent)
    }

    private static func requestFullAccess() async throws {
        guard try await store.requestFullAccessToEvents() else {
            throw CalendarError.fullAccessDenied
        }
    }

    private static func saveNewEvent(_ details: EventDetails) throws -> String? {
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendar
        }
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.notes = "Scheduled in Gather"
        apply(details, to: event)
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    private static func apply(_ details: EventDetails, to event: EKEvent) {
        event.title = details.title
        event.startDate = details.start
        event.endDate = details.end

        guard let place = details.place else {
            event.structuredLocation = nil
            event.location = nil
            return
        }
        // Calendar shows the second line as the address under the place name.
        let title = [place.name, place.address].compactMap { $0 }.joined(separator: "\n")
        if let latitude = place.latitude, let longitude = place.longitude {
            // A map location lets Calendar show directions and send "Time to Leave" alerts.
            let location = EKStructuredLocation(title: title)
            location.geoLocation = CLLocation(latitude: latitude, longitude: longitude)
            event.structuredLocation = location
        } else {
            event.structuredLocation = nil
            event.location = place.name
        }
    }
}
