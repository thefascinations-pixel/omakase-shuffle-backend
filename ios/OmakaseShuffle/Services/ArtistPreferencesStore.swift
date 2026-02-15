import Foundation

final class ArtistPreferencesStore {
    private enum Keys {
        static let artistQuery = "artistQuery"
        static let spotifyArtistId = "spotifyArtistId"
        static let artistDisplayName = "artistDisplayName"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadArtist() -> SavedArtist? {
        guard
            let artistQuery = userDefaults.string(forKey: Keys.artistQuery),
            let spotifyArtistId = userDefaults.string(forKey: Keys.spotifyArtistId),
            let artistDisplayName = userDefaults.string(forKey: Keys.artistDisplayName),
            !artistQuery.isEmpty,
            !spotifyArtistId.isEmpty
        else {
            return nil
        }

        return SavedArtist(
            artistQuery: artistQuery,
            spotifyArtistId: spotifyArtistId,
            artistDisplayName: artistDisplayName
        )
    }

    func saveArtist(_ artist: SavedArtist) {
        userDefaults.set(artist.artistQuery, forKey: Keys.artistQuery)
        userDefaults.set(artist.spotifyArtistId, forKey: Keys.spotifyArtistId)
        userDefaults.set(artist.artistDisplayName, forKey: Keys.artistDisplayName)
    }

    func clearArtist() {
        userDefaults.removeObject(forKey: Keys.artistQuery)
        userDefaults.removeObject(forKey: Keys.spotifyArtistId)
        userDefaults.removeObject(forKey: Keys.artistDisplayName)
    }
}
