import SwiftUI
import ContactsUI

/// The system contact picker, used as a fallback when Gather doesn't have Contacts access.
/// It runs outside the app, so it works without permission, but it can't search in multi-select mode.
///
/// Attach it with `.background(SystemContactPicker(...))`; it presents from a hidden host view controller
/// because wrapping `CNContactPickerViewController` directly in a SwiftUI sheet shows a blank sheet.
struct SystemContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var allowsMultipleSelection = false
    var onSelect: ([ContactSelection]) -> Void

    func makeCoordinator() -> Coordinator {
        allowsMultipleSelection ? MultipleSelectionCoordinator(parent: self) : Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        context.coordinator.parent = self
        guard isPresented, !context.coordinator.isPresenting else { return }

        context.coordinator.isPresenting = true
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        DispatchQueue.main.async {
            host.present(picker, animated: true)
        }
    }

    /// Single selection: tapping a contact picks it and closes the picker.
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: SystemContactPicker
        var isPresenting = false

        init(parent: SystemContactPicker) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            finish(with: [contact])
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            finish(with: [])
        }

        fileprivate func finish(with contacts: [CNContact]) {
            isPresenting = false
            parent.isPresented = false
            if !contacts.isEmpty {
                parent.onSelect(contacts.map { ContactSelection($0) })
            }
        }
    }

    /// The picker switches to multiple selection (checkmarks and a Done button)
    /// when its delegate implements the plural `didSelect contacts:` method.
    final class MultipleSelectionCoordinator: Coordinator {
        @objc(contactPicker:didSelectContacts:)
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            finish(with: contacts)
        }
    }
}

private extension ContactSelection {
    /// Contacts from the system picker may not include every property, so check before reading.
    init(_ contact: CNContact) {
        self.init(
            id: contact.identifier,
            name: contact.safeDisplayName,
            photoData: contact.isKeyAvailable(CNContactThumbnailImageDataKey) ? contact.thumbnailImageData : nil
        )
    }
}

private extension CNContact {
    var safeDisplayName: String {
        var parts: [String] = []
        if isKeyAvailable(CNContactGivenNameKey), !givenName.isEmpty { parts.append(givenName) }
        if isKeyAvailable(CNContactFamilyNameKey), !familyName.isEmpty { parts.append(familyName) }
        if !parts.isEmpty { return parts.joined(separator: " ") }
        if isKeyAvailable(CNContactOrganizationNameKey), !organizationName.isEmpty { return organizationName }
        return "Unnamed Contact"
    }
}
