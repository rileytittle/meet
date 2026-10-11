import SwiftUI
import SwiftData
import Contacts

struct NewStudyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var bookTitle = ""
    @State private var totalChapters = 12
    @State private var partner: CNContact?
    @State private var showingContactPicker = false

    private var trimmedTitle: String {
        bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Book name", text: $bookTitle)
                Button {
                    showingContactPicker = true
                } label: {
                    LabeledContent("Studying with", value: partner?.displayName ?? "Choose contact")
                }
                .foregroundStyle(.primary)
                Stepper("\(totalChapters) chapters", value: $totalChapters, in: 1...500)
            }
            .navigationTitle("New Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .background(
                ContactPicker(isPresented: $showingContactPicker, allowsMultipleSelection: false) { contacts in
                    partner = contacts.first
                }
            )
        }
    }

    private func save() {
        modelContext.insert(Study(
            bookTitle: trimmedTitle,
            totalChapters: totalChapters,
            partnerName: partner?.displayName,
            partnerContactIdentifier: partner?.identifier
        ))
    }
}
