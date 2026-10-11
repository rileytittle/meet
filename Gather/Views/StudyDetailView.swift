import SwiftUI
import SwiftData

struct StudyDetailView: View {
    @Bindable var study: Study
    @State private var showingContactPicker = false

    var body: some View {
        Form {
            Section("Progress") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(study.isFinished ? "Finished" : "Chapter \(study.chaptersCompleted) of \(study.totalChapters)")
                        .font(.headline)
                    ProgressView(value: study.progress)
                        .tint(study.isFinished ? Color.green : Color.accentColor)
                }
                .padding(.vertical, 4)

                Button {
                    study.chaptersCompleted += 1
                    study.lastMetAt = .now
                } label: {
                    Label("We met and finished a chapter", systemImage: "checkmark.circle")
                }
                .disabled(study.isFinished)

                Stepper("Chapters done: \(study.chaptersCompleted)",
                        value: $study.chaptersCompleted,
                        in: 0...study.totalChapters)

                LabeledContent("Last met", value: study.lastMetAt?.formatted(date: .abbreviated, time: .omitted) ?? "Not yet")
            }

            Section("Details") {
                TextField("Book name", text: $study.bookTitle)
                Button {
                    showingContactPicker = true
                } label: {
                    HStack {
                        Text("Studying with")
                        Spacer()
                        if let partnerName = study.partnerName {
                            ContactAvatar(name: partnerName, photoData: study.partnerPhotoData, size: 28)
                        }
                        Text(study.partnerName ?? "Choose contact")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                if study.partnerName != nil {
                    Button("Remove partner", role: .destructive) {
                        study.partnerName = nil
                        study.partnerContactIdentifier = nil
                        study.partnerPhotoData = nil
                    }
                }
                // Can't go below the chapters already done; lower "Chapters done" first.
                Stepper("\(study.totalChapters) chapters",
                        value: $study.totalChapters,
                        in: max(1, study.chaptersCompleted)...500)
            }
        }
        .navigationTitle(study.bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContactPicker) {
            ContactsPickerView(title: "Studying With") { contacts in
                guard let contact = contacts.first else { return }
                study.partnerName = contact.name
                study.partnerContactIdentifier = contact.id
                study.partnerPhotoData = contact.photoData
            }
        }
    }
}
