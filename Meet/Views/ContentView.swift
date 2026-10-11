import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var people: [Person]
    @Query private var studies: [Study]

    var body: some View {
        TabView {
            PeopleListView()
                .tabItem { Label("Meet", systemImage: "person.2") }
            PrayerListView()
                .tabItem { Label("Prayer", systemImage: "hands.and.sparkles") }
            StudiesListView()
                .tabItem { Label("Studies", systemImage: "book") }
        }
        .task { await refreshContactPhotos() }
    }

    /// Pulls the latest contact photos so changes made in Contacts show up here.
    /// Does nothing until Contacts access has been granted.
    private func refreshContactPhotos() async {
        let identifiers = Array(Set(people.compactMap(\.contactIdentifier) + studies.compactMap(\.partnerContactIdentifier)))
        guard !identifiers.isEmpty else { return }

        let photos = await Task.detached(priority: .utility) {
            ContactsService.photos(for: identifiers)
        }.value

        for person in people {
            if let id = person.contactIdentifier, let photo = photos[id], photo != person.photoData {
                person.photoData = photo
            }
        }
        for study in studies {
            if let id = study.partnerContactIdentifier, let photo = photos[id], photo != study.partnerPhotoData {
                study.partnerPhotoData = photo
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self], inMemory: true)
}
