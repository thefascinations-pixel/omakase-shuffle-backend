import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: OmakaseViewModel

    var body: some View {
        Group {
            switch viewModel.screen {
            case .artistInput:
                ArtistInputView(viewModel: viewModel)
            case .main:
                MainView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.light)
    }
}
