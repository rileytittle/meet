import SwiftUI
import SwiftData

@main
struct GatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Person.self, PrayerRequest.self, Study.self, Meeting.self])
    }
}
