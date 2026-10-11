import Foundation
import Contacts

/// A contact chosen in `ContactsPickerView`.
struct ContactSelection: Identifiable, Hashable {
    let id: String
    let name: String
    let photoData: Data?
}

/// Reads contacts and their photos. Requires Contacts access (`NSContactsUsageDescription`).
enum ContactsService {
    private static let keys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
    ]

    static var hasAccess: Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined, .denied, .restricted: false
        default: true // .authorized, or .limited on iOS 18 (only the contacts the user shared)
        }
    }

    static func requestAccess() async -> Bool {
        (try? await CNContactStore().requestAccess(for: .contacts)) ?? false
    }

    /// All contacts in the user's preferred sort order. Blocks, so call it off the main thread.
    static func fetchAll() throws -> [ContactSelection] {
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        var results: [ContactSelection] = []
        try CNContactStore().enumerateContacts(with: request) { contact, _ in
            results.append(ContactSelection(id: contact.identifier, name: contact.displayName, photoData: contact.thumbnailImageData))
        }
        return results
    }

    /// Current photo thumbnails for the given contact identifiers, keyed by identifier.
    /// Contacts without a photo map to nil. Blocks, so call it off the main thread.
    static func photos(for identifiers: [String]) -> [String: Data?] {
        guard hasAccess, !identifiers.isEmpty else { return [:] }
        let predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        let contacts = (try? CNContactStore().unifiedContacts(matching: predicate, keysToFetch: keys)) ?? []
        return Dictionary(contacts.map { ($0.identifier, $0.thumbnailImageData) }, uniquingKeysWith: { first, _ in first })
    }
}

extension CNContact {
    var displayName: String {
        let full = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
        if !full.isEmpty { return full }
        if !organizationName.isEmpty { return organizationName }
        return "Unnamed Contact"
    }
}
