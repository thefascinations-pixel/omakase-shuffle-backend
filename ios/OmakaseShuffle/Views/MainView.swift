import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: OmakaseViewModel
    @Environment(\.openURL) private var openURL

    private var displayArtistName: String {
        if let savedArtist = viewModel.savedArtist {
            return savedArtist.artistDisplayName.isEmpty
                ? savedArtist.artistQuery
                : savedArtist.artistDisplayName
        }
        return "Unknown Artist"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            VStack(spacing: 26) {
                Spacer(minLength: 20)

                Text(displayArtistName)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.96))
                    .padding(.horizontal, 20)

                Button {
                    Task {
                        await viewModel.pickRandomSong()
                    }
                } label: {
                    Text("pick\nrandom\nsong")
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.95))
                        .frame(width: 310, height: 310)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.20))
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.38), lineWidth: 1.2)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 12, y: 8)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isFindingTrack)

                if viewModel.isFindingTrack {
                    Text("finding a song…")
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.94))
                } else {
                    Text("tap to find a song")
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.94))
                }

                if let trackResult = viewModel.trackResult {
                    VStack(spacing: 8) {
                        Text(trackResult.trackName)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                        Text(trackResult.albumName)
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .opacity(0.9)
                        Button("Open in Spotify") {
                            if let spotifyURL = URL(string: trackResult.spotifyUrl) {
                                openURL(spotifyURL)
                            }
                        }
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.20))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 24)
                }

                if let trackErrorMessage = viewModel.trackErrorMessage {
                    Text(trackErrorMessage)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 42)
            .padding(.bottom, 16)

            Button {
                viewModel.clearArtistSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .light))
                    Text("Change artist")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(16)
        }
    }
}
