import Foundation
import SwiftData

@Model
final class PrayerRequest {
    var text: String
    var createdAt: Date
    var person: Person?

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}
