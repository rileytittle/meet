import SwiftUI
import ContactsUI

/// Presents the system contact picker (multi-select) when `isPresented` becomes true.
/// The system picker runs out of process, so no Contacts permission prompt is needed.
///
/// Attach it with `.background(ContactPicker(...))`. It presents from a hidden host
/// view controller because wrapping `CNContactPickerViewController` directly in a
/// SwiftUI sheet shows a blank sheet.
struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onSelect: ([CNContact]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
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

    final class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        var isPresenting = false

        init(parent: ContactPicker) {
            self.parent = parent
        }

        // Implementing the plural variant enables multiple selection.
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.onSelect(contacts)
            finish()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            finish()
        }

        private func finish() {
            isPresenting = false
            parent.isPresented = false
        }
    }
}

extension CNContact {
    var displayName: String {
        var parts: [String] = []
        if isKeyAvailable(CNContactGivenNameKey), !givenName.isEmpty { parts.append(givenName) }
        if isKeyAvailable(CNContactFamilyNameKey), !familyName.isEmpty { parts.append(familyName) }
        if !parts.isEmpty { return parts.joined(separator: " ") }
        if isKeyAvailable(CNContactOrganizationNameKey), !organizationName.isEmpty { return organizationName }
        return "Unnamed Contact"
    }
}
