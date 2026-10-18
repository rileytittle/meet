import SwiftUI
import MapKit

/// Search Apple Maps for a meeting place, or use whatever was typed as a plain name.
struct PlacePickerView: View {
    let onSelect: (MeetingPlace) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = PlaceSearch()
    @State private var isResolving = false
    @State private var errorMessage: String?

    private var typedText: String {
        search.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(search.results, id: \.self) { completion in
                    Button {
                        Task { await select(completion) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if !typedText.isEmpty {
                    Button {
                        choose(MeetingPlace(name: typedText))
                    } label: {
                        Label("Use “\(typedText)” without a map location", systemImage: "text.cursor")
                    }
                }
            }
            .listStyle(.plain)
            .disabled(isResolving)
            .overlay {
                if isResolving {
                    ProgressView()
                } else if typedText.isEmpty {
                    ContentUnavailableView(
                        "Find a Place",
                        systemImage: "mappin.and.ellipse",
                        description: Text("Search for a coffee shop, church, address, or any place on the map.")
                    )
                }
            }
            .searchable(text: queryBinding, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for a place")
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't Find That Place", isPresented: showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var queryBinding: Binding<String> {
        Binding(get: { search.query }, set: { search.update(query: $0) })
    }

    private var showingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func select(_ completion: MKLocalSearchCompletion) async {
        isResolving = true
        defer { isResolving = false }
        do {
            choose(try await search.resolve(completion))
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func choose(_ place: MeetingPlace) {
        onSelect(place)
        dismiss()
    }
}
