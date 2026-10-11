import SwiftUI

struct PrayerRequestEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var text: String

    let title: String
    let onSave: (String) -> Void

    init(title: String, initialText: String = "", onSave: @escaping (String) -> Void) {
        self.title = title
        self._text = State(initialValue: initialText)
        self.onSave = onSave
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("What can you pray for?", text: $text, axis: .vertical)
                    .lineLimit(5...12)
                    .focused($isFocused)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedText)
                        dismiss()
                    }
                    .disabled(trimmedText.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
