import Foundation

final class APIClient {
    enum APIClientError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case transportError(String)
        case notFound(String)
        case serverError(String)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "Backend URL is invalid. Update AppConfig.backendBaseURL."
            case .invalidResponse:
                return "Unexpected response from the server."
            case .transportError(let message):
                return message
            case .notFound(let message):
                return message
            case .serverError(let message):
                return message
            case .decodingError:
                return "Could not parse the server response."
            }
        }
    }

    private let baseURLString: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURLString: String = AppConfig.backendBaseURL, session: URLSession = .shared) {
        self.baseURLString = baseURLString
        self.session = session
    }

    func resolveArtist(artistQuery: String) async throws -> ArtistResolutionResponse {
        let payload = ["artistQuery": artistQuery]
        guard let bodyData = try? encoder.encode(payload) else {
            throw APIClientError.invalidResponse
        }

        var request = try makeRequest(path: "/api/resolve-artist")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        return try await perform(request, decodeTo: ArtistResolutionResponse.self)
    }

    func randomTrack(artistQuery: String, artistId: String?) async throws -> RandomTrackResponse {
        var components = URLComponents()
        components.path = "/api/random-track"

        var queryItems = [URLQueryItem(name: "artistQuery", value: artistQuery)]
        if let artistId, !artistId.isEmpty {
            queryItems.append(URLQueryItem(name: "artistId", value: artistId))
        }
        components.queryItems = queryItems

        guard let pathWithQuery = components.string else {
            throw APIClientError.invalidResponse
        }

        let request = try makeRequest(path: pathWithQuery)
        return try await perform(request, decodeTo: RandomTrackResponse.self)
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let baseURL = URL(string: baseURLString) else {
            throw APIClientError.invalidBaseURL
        }

        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest, decodeTo type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if let urlError = error as? URLError {
                throw APIClientError.transportError(urlError.localizedDescription)
            }
            throw APIClientError.transportError("Network request failed.")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            guard let decoded = try? decoder.decode(type, from: data) else {
                throw APIClientError.decodingError
            }
            return decoded
        }

        let apiError = (try? decoder.decode(APIErrorResponse.self, from: data))?.error
        let fallback = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
        let message = apiError ?? fallback

        if httpResponse.statusCode == 404 {
            throw APIClientError.notFound(message)
        }
        throw APIClientError.serverError(message)
    }
}
