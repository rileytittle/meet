import SwiftUI
import SwiftData

@main
struct MeetApp: App {
    var body: some Scene {
        WindowGroup {
            PeopleListView()
        }
        .modelContainer(for: [Person.self, PrayerRequest.self])
    }
}
