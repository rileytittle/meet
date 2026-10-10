import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingRequest = false
    @State private var editingRequest: PrayerRequest?

    private static let reminderOptions: [(days: Int, label: String)] = [
        (7, "Every week"),
        (14, "Every 2 weeks"),
        (30, "Every month"),
        (90, "Every 3 months"),
        (0, "Off"),
    ]

    /// Newest first.
    private var sortedRequests: [PrayerRequest] {
        person.prayerRequests.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
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
                Picker("Remind me", selection: $person.reminderIntervalDays) {
                    ForEach(Self.reminderOptions, id: \.days) { option in
                        Text(option.label).tag(option.days)
                    }
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
        .onChange(of: person.reminderIntervalDays) {
            ReminderScheduler.schedule(for: person)
        }
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
