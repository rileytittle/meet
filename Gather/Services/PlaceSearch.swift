import Foundation
import MapKit
import Observation

/// A meeting place: either a real map location or just a typed name.
struct MeetingPlace: Equatable {
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?

    var hasCoordinate: Bool { latitude != nil && longitude != nil }
}

/// Searches Apple Maps for places as the user types. Needs no location permission.
@Observable
final class PlaceSearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var query = ""
    private(set) var results: [MKLocalSearchCompletion] = []

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    enum SearchError: LocalizedError {
        case notFound

        var errorDescription: String? { "That place couldn't be found on the map." }
    }

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func update(query: String) {
        self.query = query
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = query.isEmpty ? [] : completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }

    /// Looks up the full details (address and coordinates) for a search suggestion.
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> MeetingPlace {
        let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()
        guard let item = response.mapItems.first else { throw SearchError.notFound }

        let coordinate = item.placemark.coordinate
        let address = completion.subtitle.isEmpty ? item.placemark.title : completion.subtitle
        return MeetingPlace(
            name: item.name ?? completion.title,
            address: address?.isEmpty == false ? address : nil,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
