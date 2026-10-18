import SwiftUI
import SwiftData

/// Schedules a new meeting with a person, or edits an existing one,
/// keeping the iPhone calendar event in sync when there is one.
struct MeetingEditorView: View {
    let person: Person
    /// The meeting being edited, or nil when scheduling a new one.
    let meeting: Meeting?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var date: Date
    @State private var durationMinutes: Int
    @State private var place: MeetingPlace?
    @State private var syncWithCalendar: Bool
    @State private var showingPlacePicker = false
    @State private var isSaving = false
    @State private var calendarErrorMessage: String?

    private static let durations: [(minutes: Int, label: String)] = [
        (30, "30 minutes"),
        (60, "1 hour"),
        (90, "1½ hours"),
        (120, "2 hours"),
    ]

    init(person: Person, meeting: Meeting? = nil) {
        self.person = person
        self.meeting = meeting
        _title = State(initialValue: meeting?.title ?? "Meet with \(person.name)")
        _date = State(initialValue: meeting?.date ?? Self.nextFullHour())
        _durationMinutes = State(initialValue: meeting?.durationMinutes ?? 60)
        _place = State(initialValue: meeting?.place)
        // New meetings go on the calendar by default; edits keep whatever was chosen before.
        _syncWithCalendar = State(initialValue: meeting.map { $0.calendarEventID != nil } ?? true)
    }

    private var isEditing: Bool { meeting != nil }
    private var hasCalendarEvent: Bool { meeting?.calendarEventID != nil }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                }

                Section {
                    Button {
                        showingPlacePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: place?.hasCoordinate == true ? "mappin.circle.fill" : "mappin.and.ellipse")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place?.name ?? "Add a place")
                                    .foregroundStyle(place == nil ? .secondary : .primary)
                                if let address = place?.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if place != nil {
                        Button("Remove Place", role: .destructive) { place = nil }
                    }
                } footer: {
                    if place?.hasCoordinate == true {
                        Text("With a map location, Calendar can show directions and send a Time to Leave alert based on travel time.")
                    }
                }

                Section {
                    DatePicker("Starts", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Length", selection: $durationMinutes) {
                        ForEach(Self.durations, id: \.minutes) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }
                }

                Section {
                    Toggle(hasCalendarEvent ? "Update in Calendar" : "Add to Calendar", isOn: $syncWithCalendar)
                } footer: {
                    if !isEditing {
                        Text("Your reminders to meet with \(person.name) will start counting from this meeting.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Meeting" : "Schedule Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedTitle.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingPlacePicker) {
                PlacePickerView { place = $0 }
            }
            .alert("Couldn't Update Calendar", isPresented: showingCalendarError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(calendarErrorMessage ?? "") The meeting is still saved in Gather.")
            }
        }
    }

    /// Closes the sheet once the calendar error alert is dismissed.
    private var showingCalendarError: Binding<Bool> {
        Binding(
            get: { calendarErrorMessage != nil },
            set: { isShowing in
                if !isShowing {
                    calendarErrorMessage = nil
                    dismiss()
                }
            }
        )
    }

    private func save() {
        isSaving = true

        let meeting: Meeting
        if let existing = self.meeting {
            meeting = existing
        } else {
            meeting = Meeting(title: trimmedTitle, date: date)
            modelContext.insert(meeting)
            person.meetings.append(meeting)
        }
        meeting.title = trimmedTitle
        meeting.date = date
        meeting.durationMinutes = durationMinutes
        meeting.place = place
        ReminderScheduler.schedule(for: person)

        guard syncWithCalendar else {
            dismiss()
            return
        }
        let details = CalendarService.EventDetails(meeting)
        Task {
            do {
                if let eventID = meeting.calendarEventID {
                    meeting.calendarEventID = try await CalendarService.updateEvent(id: eventID, with: details)
                } else {
                    meeting.calendarEventID = try await CalendarService.addEvent(details)
                }
                dismiss()
            } catch {
                calendarErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    /// The start of the next hour, e.g. 3:00 PM when it's 2:20 PM.
    private static func nextFullHour() -> Date {
        let calendar = Calendar.current
        let inAnHour = calendar.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: inAnHour)
        return calendar.date(from: components) ?? inAnHour
    }
}
