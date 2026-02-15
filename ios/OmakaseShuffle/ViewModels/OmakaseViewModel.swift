import Foundation

@MainActor
final class OmakaseViewModel: ObservableObject {
    enum Screen {
        case artistInput
        case main
    }

    @Published private(set) var screen: Screen = .artistInput
    @Published private(set) var savedArtist: SavedArtist?
    @Published private(set) var isResolvingArtist = false
    @Published private(set) var inputErrorMessage: String?
    @Published private(set) var isFindingTrack = false
    @Published private(set) var trackResult: RandomTrackResponse?
    @Published private(set) var trackErrorMessage: String?

    private let apiClient: APIClient
    private let store: ArtistPreferencesStore
    private var lastResolvedQuery = ""

    init(apiClient: APIClient = APIClient(), store: ArtistPreferencesStore = ArtistPreferencesStore()) {
        self.apiClient = apiClient
        self.store = store
        self.savedArtist = store.loadArtist()
        self.screen = savedArtist == nil ? .artistInput : .main
    }

    func resolveAndSaveArtist(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        if trimmedQuery == lastResolvedQuery, savedArtist?.artistQuery == trimmedQuery {
            screen = .main
            inputErrorMessage = nil
            return
        }

        if isResolvingArtist {
            return
        }

        isResolvingArtist = true
        inputErrorMessage = nil

        do {
            let response = try await apiClient.resolveArtist(artistQuery: trimmedQuery)
            let newArtist = SavedArtist(
                artistQuery: trimmedQuery,
                spotifyArtistId: response.artistId,
                artistDisplayName: response.artistDisplayName
            )

            store.saveArtist(newArtist)
            savedArtist = newArtist
            lastResolvedQuery = trimmedQuery
            trackResult = nil
            trackErrorMessage = nil
            screen = .main
        } catch {
            inputErrorMessage = error.localizedDescription
        }

        isResolvingArtist = false
    }

    func pickRandomSong() async {
        guard let savedArtist else {
            trackErrorMessage = "Please set an artist first."
            screen = .artistInput
            return
        }

        isFindingTrack = true
        trackErrorMessage = nil
        trackResult = nil

        do {
            let track = try await apiClient.randomTrack(
                artistQuery: savedArtist.artistQuery,
                artistId: savedArtist.spotifyArtistId
            )
            trackResult = track
        } catch {
            trackErrorMessage = error.localizedDescription
        }

        isFindingTrack = false
    }

    func clearArtistSelection() {
        store.clearArtist()
        savedArtist = nil
        inputErrorMessage = nil
        trackResult = nil
        trackErrorMessage = nil
        lastResolvedQuery = ""
        screen = .artistInput
    }
}
