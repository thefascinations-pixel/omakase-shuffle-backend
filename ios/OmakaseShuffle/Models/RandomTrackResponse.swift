import Foundation

struct RandomTrackResponse: Decodable {
    let trackName: String
    let albumName: String
    let spotifyUrl: String
}
