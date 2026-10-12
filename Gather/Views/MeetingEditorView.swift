import SwiftUI
import SwiftData

/// Schedules a meeting with a person and optionally adds it to the iPhone calendar.
struct MeetingEditorView: View {
    let person: Person

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var date: Date
    @State private var durationMinutes = 60
    @State private var location = ""
    @State private var addToCalendar = true
    @State private var isSaving = false
    @State private var calendarErrorMessage: String?

    private static let durations: [(minutes: Int, label: String)] = [
        (30, "30 minutes"),
        (60, "1 hour"),
        (90, "1½ hours"),
        (120, "2 hours"),
    ]

    init(person: Person) {
        self.person = person
        _title = State(initialValue: "Meet with \(person.name)")
        _date = State(initialValue: Self.nextFullHour())
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Place", text: $location)
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
                    Toggle("Add to Calendar", isOn: $addToCalendar)
                } footer: {
                    Text("Your reminders to meet with \(person.name) will start counting from this meeting.")
                }
            }
            .navigationTitle("Schedule Meeting")
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
            .alert("Couldn't Add to Calendar", isPresented: showingCalendarError) {
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
        let meeting = Meeting(
            title: trimmedTitle,
            date: date,
            durationMinutes: durationMinutes,
            location: trimmedLocation.isEmpty ? nil : trimmedLocation
        )
        modelContext.insert(meeting)
        person.meetings.append(meeting)
        ReminderScheduler.schedule(for: person)

        guard addToCalendar else {
            dismiss()
            return
        }
        Task {
            do {
                meeting.calendarEventID = try await CalendarService.addEvent(
                    title: meeting.title,
                    start: meeting.date,
                    end: meeting.endDate,
                    location: meeting.location,
                    notes: "Scheduled in Gather"
                )
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
