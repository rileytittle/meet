import Foundation
import SwiftData

@Model
final class PrayerRequest {
    var text: String
    var createdAt: Date
    /// The person this request is for, or nil for a general prayer.
    var person: Person?
    /// When this was last marked as prayed for. Nil means not prayed for yet.
    var lastPrayedAt: Date? = nil

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}

extension PrayerRequest {
    /// Order for the Prayer tab: unprayed requests first (newest first), then prayed ones
    /// with the longest-ago prayed at the top, so each one rises as others are prayed for.
    static func prayerListOrder(_ lhs: PrayerRequest, _ rhs: PrayerRequest) -> Bool {
        switch (lhs.lastPrayedAt, rhs.lastPrayedAt) {
        case (nil, nil): return lhs.createdAt > rhs.createdAt
        case (nil, _): return true
        case (_, nil): return false
        case let (l?, r?): return l < r
        }
    }
}
