import Foundation
import SwiftData

@Model
final class Study {
    var bookTitle: String
    var totalChapters: Int
    var chaptersCompleted: Int
    /// Name of the contact you're studying with, if any.
    var partnerName: String?
    var partnerContactIdentifier: String?
    @Attribute(.externalStorage) var partnerPhotoData: Data? = nil
    var lastMetAt: Date?
    var createdAt: Date

    init(bookTitle: String, totalChapters: Int, partnerName: String? = nil, partnerContactIdentifier: String? = nil) {
        self.bookTitle = bookTitle
        self.totalChapters = totalChapters
        self.chaptersCompleted = 0
        self.partnerName = partnerName
        self.partnerContactIdentifier = partnerContactIdentifier
        self.lastMetAt = nil
        self.createdAt = .now
    }

    var isFinished: Bool { chaptersCompleted >= totalChapters }

    var progress: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(min(chaptersCompleted, totalChapters)) / Double(totalChapters)
    }
}
