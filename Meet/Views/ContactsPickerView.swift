import SwiftUI

/// Searchable contact list with photos. Present it in a sheet.
/// With multiple selection, tap contacts to check them and then tap Add.
/// With single selection, tapping a contact picks it and closes the sheet.
struct ContactsPickerView: View {
    let title: String
    var allowsMultipleSelection = false
    /// Contacts already added; shown as "Added" and can't be picked again.
    var excludedIdentifiers: Set<String> = []
    let onDone: ([ContactSelection]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var contacts: [ContactSelection] = []
    @State private var selectedIDs: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var accessDenied = false

    private var filteredContacts: [ContactSelection] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var addButtonTitle: String {
        selectedIDs.isEmpty ? "Add" : "Add (\(selectedIDs.count))"
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    if allowsMultipleSelection {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(addButtonTitle) {
                                onDone(contacts.filter { selectedIDs.contains($0.id) })
                                dismiss()
                            }
                            .disabled(selectedIDs.isEmpty)
                        }
                    }
                }
        }
        .task { await loadContacts() }
    }

    @ViewBuilder
    private var content: some View {
        if accessDenied {
            ContentUnavailableView {
                Label("No Access to Contacts", systemImage: "person.crop.circle.badge.exclamationmark")
            } description: {
                Text("Allow Meet to access your contacts in Settings to add people.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } else if isLoading {
            ProgressView()
        } else {
            List(filteredContacts) { contact in
                row(for: contact)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search contacts")
            .overlay {
                if filteredContacts.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView("No Contacts", systemImage: "person.crop.circle")
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
    }

    private func row(for contact: ContactSelection) -> some View {
        let isExcluded = excludedIdentifiers.contains(contact.id)
        return Button {
            select(contact)
        } label: {
            HStack(spacing: 12) {
                ContactAvatar(name: contact.name, photoData: contact.photoData, size: 36)
                Text(contact.name)
                    .foregroundStyle(isExcluded ? .secondary : .primary)
                Spacer()
                if isExcluded {
                    Text("Added")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if selectedIDs.contains(contact.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isExcluded)
    }

    private func select(_ contact: ContactSelection) {
        guard allowsMultipleSelection else {
            onDone([contact])
            dismiss()
            return
        }
        if selectedIDs.contains(contact.id) {
            selectedIDs.remove(contact.id)
        } else {
            selectedIDs.insert(contact.id)
        }
    }

    private func loadContacts() async {
        defer { isLoading = false }
        guard await ContactsService.requestAccess() else {
            accessDenied = true
            return
        }
        do {
            contacts = try await Task.detached(priority: .userInitiated) {
                try ContactsService.fetchAll()
            }.value
        } catch {
            accessDenied = true
        }
    }
}
