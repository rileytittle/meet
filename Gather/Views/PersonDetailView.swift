import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingRequest = false
    @State private var editingRequest: PrayerRequest?

    /// Newest first.
    private var sortedRequests: [PrayerRequest] {
        person.prayerRequests.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                ContactAvatar(name: person.name, photoData: person.photoData, size: 88)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            Section("Prayer Requests") {
                if sortedRequests.isEmpty {
                    Text("No prayer requests yet. Tap + to add one.")
                        .foregroundStyle(.secondary)
                }
                ForEach(sortedRequests) { request in
                    Button {
                        editingRequest = request
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.text)
                                .foregroundStyle(.primary)
                            Text(request.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteRequests)
            }

            Section("Meeting Reminder") {
                Toggle("Remind me to meet", isOn: remindersEnabled)
                if person.remindersEnabled {
                    Stepper(value: $person.reminderEvery, in: 1...365) {
                        Text(person.frequencyDescription)
                    }
                    Picker("Unit", selection: $person.reminderUnit) {
                        ForEach(ReminderUnit.allCases) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Start date", selection: startDate, displayedComponents: .date)
                }
                LabeledContent("Last met", value: person.lastMetAt?.formatted(date: .abbreviated, time: .omitted) ?? "Not yet")
                if let due = person.nextMeetingDue {
                    LabeledContent("Next reminder", value: due.formatted(date: .abbreviated, time: .omitted))
                }
                Button("We met today") {
                    person.lastMetAt = .now
                    ReminderScheduler.schedule(for: person)
                }
            }
        }
        .navigationTitle(person.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingRequest = true
                } label: {
                    Label("Add Prayer Request", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingRequest) {
            PrayerRequestEditor(title: "New Prayer Request") { text in
                let request = PrayerRequest(text: text)
                modelContext.insert(request)
                request.person = person
            }
        }
        .sheet(item: $editingRequest) { request in
            PrayerRequestEditor(title: "Edit Prayer Request", initialText: request.text) { text in
                request.text = text
            }
        }
        .onChange(of: person.reminderIntervalDays) { ReminderScheduler.schedule(for: person) }
        .onChange(of: person.reminderUnitRaw) { ReminderScheduler.schedule(for: person) }
        .onChange(of: person.reminderStartDate) { ReminderScheduler.schedule(for: person) }
    }

    private var remindersEnabled: Binding<Bool> {
        Binding(
            get: { person.remindersEnabled },
            set: { person.reminderEvery = $0 ? 1 : 0 }
        )
    }

    /// Shows the chosen start date, or the default first reminder (one interval after the person was added).
    private var startDate: Binding<Date> {
        Binding(
            get: {
                person.reminderStartDate
                    ?? Calendar.current.date(byAdding: person.reminderUnit.calendarComponent, value: person.reminderEvery, to: person.createdAt)
                    ?? .now
            },
            set: { person.reminderStartDate = Calendar.current.startOfDay(for: $0) }
        )
    }

    private func deleteRequests(at offsets: IndexSet) {
        let snapshot = sortedRequests
        for index in offsets {
            let request = snapshot[index]
            person.prayerRequests.removeAll { $0 == request }
            modelContext.delete(request)
        }
    }
}
