import SwiftUI

@main
struct OmakaseShuffleApp: App {
    @StateObject private var viewModel = OmakaseViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
        }
    }
}
