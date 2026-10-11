import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            PeopleListView()
                .tabItem { Label("Meet", systemImage: "person.2") }
            PrayerListView()
                .tabItem { Label("Prayer", systemImage: "hands.and.sparkles") }
            StudiesListView()
                .tabItem { Label("Studies", systemImage: "book") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self], inMemory: true)
}
