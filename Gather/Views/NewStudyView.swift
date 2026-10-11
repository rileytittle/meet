import SwiftUI
import SwiftData

struct NewStudyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var bookTitle = ""
    @State private var totalChapters = 12
    @State private var partner: ContactSelection?
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
                    HStack {
                        Text("Studying with")
                        Spacer()
                        if let partner {
                            ContactAvatar(name: partner.name, photoData: partner.photoData, size: 28)
                        }
                        Text(partner?.name ?? "Choose contact")
                            .foregroundStyle(.secondary)
                    }
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
            .sheet(isPresented: $showingContactPicker) {
                ContactsPickerView(title: "Studying With") { contacts in
                    partner = contacts.first
                }
            }
        }
    }

    private func save() {
        let study = Study(
            bookTitle: trimmedTitle,
            totalChapters: totalChapters,
            partnerName: partner?.name,
            partnerContactIdentifier: partner?.id
        )
        study.partnerPhotoData = partner?.photoData
        modelContext.insert(study)
    }
}
