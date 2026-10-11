import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    @State private var showingContactPicker = false

    /// People whose meeting is due soonest come first; people with reminders off go last.
    private var sortedPeople: [Person] {
        people.sorted {
            let lhs = $0.nextMeetingDue ?? .distantFuture
            let rhs = $1.nextMeetingDue ?? .distantFuture
            return lhs == rhs ? $0.name < $1.name : lhs < rhs
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedPeople) { person in
                    NavigationLink(value: person) {
                        PersonRow(person: person)
                    }
                }
                .onDelete(perform: deletePeople)
            }
            .overlay {
                if people.isEmpty {
                    ContentUnavailableView(
                        "No People Yet",
                        systemImage: "person.2",
                        description: Text("Tap + to add people from your contacts.")
                    )
                }
            }
            .navigationTitle("Meet")
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(person: person)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingContactPicker = true
                    } label: {
                        Label("Add People", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactsPickerView(
                    title: "Add People",
                    allowsMultipleSelection: true,
                    excludedIdentifiers: Set(people.compactMap(\.contactIdentifier)),
                    onDone: addPeople
                )
            }
            .task {
                // Refresh reminders on launch so overdue people get nudged again.
                for person in people {
                    ReminderScheduler.schedule(for: person)
                }
            }
        }
    }

    private func addPeople(from contacts: [ContactSelection]) {
        let existingIDs = Set(people.compactMap(\.contactIdentifier))
        let newPeople = contacts
            .filter { !existingIDs.contains($0.id) }
            .map { Person(name: $0.name, contactIdentifier: $0.id, photoData: $0.photoData) }

        guard !newPeople.isEmpty else { return }
        for person in newPeople {
            modelContext.insert(person)
        }

        Task { @MainActor in
            await ReminderScheduler.requestAuthorization()
            newPeople.forEach(ReminderScheduler.schedule(for:))
        }
    }

    private func deletePeople(at offsets: IndexSet) {
        let snapshot = sortedPeople
        for index in offsets {
            let person = snapshot[index]
            ReminderScheduler.cancel(for: person)
            modelContext.delete(person)
        }
    }
}

private struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            ContactAvatar(name: person.name, photoData: person.photoData, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.headline)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(person.isDue ? .red : .secondary)
            }
            Spacer()
            if !person.prayerRequests.isEmpty {
                Label("\(person.prayerRequests.count)", systemImage: "hands.and.sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusText: String {
        guard let due = person.nextMeetingDue else { return "No reminder" }
        if person.isDue { return "Time to meet" }
        return "Meet \(due.formatted(.relative(presentation: .named)))"
    }
}

#Preview {
    PeopleListView()
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self], inMemory: true)
}
