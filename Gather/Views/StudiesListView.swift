import SwiftUI
import SwiftData

struct StudiesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Study.createdAt, order: .reverse) private var studies: [Study]
    @State private var isAddingStudy = false

    /// In-progress studies first, finished ones at the bottom.
    private var sortedStudies: [Study] {
        studies.filter { !$0.isFinished } + studies.filter(\.isFinished)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedStudies) { study in
                    NavigationLink(value: study) {
                        StudyRow(study: study)
                    }
                }
                .onDelete(perform: deleteStudies)
            }
            .overlay {
                if studies.isEmpty {
                    ContentUnavailableView(
                        "No Studies Yet",
                        systemImage: "book",
                        description: Text("Tap + to add a book you're studying with someone.")
                    )
                }
            }
            .navigationTitle("Studies")
            .navigationDestination(for: Study.self) { study in
                StudyDetailView(study: study)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingStudy = true
                    } label: {
                        Label("Add Study", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingStudy) {
                NewStudyView()
            }
        }
    }

    private func deleteStudies(at offsets: IndexSet) {
        let snapshot = sortedStudies
        for index in offsets {
            modelContext.delete(snapshot[index])
        }
    }
}

private struct StudyRow: View {
    let study: Study

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(study.bookTitle)
                .font(.headline)
            if let partnerName = study.partnerName {
                HStack(spacing: 6) {
                    ContactAvatar(name: partnerName, photoData: study.partnerPhotoData, size: 20)
                    Text("with \(partnerName)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            ProgressView(value: study.progress)
                .tint(study.isFinished ? Color.green : Color.accentColor)
            Text(study.isFinished ? "Finished" : "Chapter \(study.chaptersCompleted) of \(study.totalChapters)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StudiesListView()
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self], inMemory: true)
}
