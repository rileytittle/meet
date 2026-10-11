import SwiftUI
import SwiftData

/// Every prayer request in one list: general ones plus those attached to people.
/// Swipe right to mark as prayed for (moves it to the bottom), swipe left to delete.
struct PrayerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var requests: [PrayerRequest]
    @State private var isAddingRequest = false
    @State private var editingRequest: PrayerRequest?

    private var sortedRequests: [PrayerRequest] {
        requests.sorted(by: PrayerRequest.prayerListOrder)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedRequests) { request in
                    PrayerCard(request: request)
                        .contentShape(Rectangle())
                        .onTapGesture { editingRequest = request }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                markPrayedFor(request)
                            } label: {
                                Label("Prayed", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(request)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .overlay {
                if requests.isEmpty {
                    ContentUnavailableView(
                        "No Prayers Yet",
                        systemImage: "hands.and.sparkles",
                        description: Text("Tap + to add a prayer. Prayer requests you add for people show up here too.")
                    )
                }
            }
            .navigationTitle("Prayer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingRequest = true
                    } label: {
                        Label("Add Prayer", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingRequest) {
                PrayerRequestEditor(title: "New Prayer") { text in
                    modelContext.insert(PrayerRequest(text: text))
                }
            }
            .sheet(item: $editingRequest) { request in
                PrayerRequestEditor(title: "Edit Prayer", initialText: request.text) { text in
                    request.text = text
                }
            }
        }
    }

    private func markPrayedFor(_ request: PrayerRequest) {
        withAnimation {
            request.lastPrayedAt = .now
        }
    }

    private func delete(_ request: PrayerRequest) {
        withAnimation {
            request.person?.prayerRequests.removeAll { $0 == request }
            modelContext.delete(request)
        }
    }
}

private struct PrayerCard: View {
    let request: PrayerRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(request.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            if request.person != nil || request.lastPrayedAt != nil {
                HStack {
                    if let person = request.person {
                        Text(person.name)
                    }
                    Spacer()
                    if let prayedAt = request.lastPrayedAt {
                        Label(prayedText(prayedAt), systemImage: "checkmark")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .opacity(request.lastPrayedAt == nil ? 1 : 0.7)
    }

    private func prayedText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Prayed today" }
        return "Prayed \(date.formatted(.relative(presentation: .named)))"
    }
}

#Preview {
    PrayerListView()
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self], inMemory: true)
}
