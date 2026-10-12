import Foundation
import EventKit

/// Adds meetings to the user's calendar. Asks only for permission to add events,
/// so Gather can never read what's already on the calendar.
enum CalendarService {
    private static let store = EKEventStore()

    enum CalendarError: LocalizedError {
        case accessDenied
        case noCalendar

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                "Gather doesn't have permission to add events. You can allow it in Settings → Gather → Calendars."
            case .noCalendar:
                "There's no calendar set up on this iPhone to add the event to."
            }
        }
    }

    /// Adds an event to the default calendar and returns its identifier.
    /// Asks for permission the first time.
    static func addEvent(title: String, start: Date, end: Date, location: String?, notes: String?) async throws -> String? {
        guard try await store.requestWriteOnlyAccessToEvents() else {
            throw CalendarError.accessDenied
        }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendar
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.location = location
        event.notes = notes
        event.calendar = calendar
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }
}
