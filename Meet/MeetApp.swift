import SwiftUI
import SwiftData

@main
struct MeetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self])
    }
}
