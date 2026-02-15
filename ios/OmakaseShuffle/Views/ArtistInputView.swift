import SwiftUI

struct ArtistInputView: View {
    @ObservedObject var viewModel: OmakaseViewModel

    @State private var artistInput: String
    @State private var debounceTask: Task<Void, Never>?
    @FocusState private var isTextFieldFocused: Bool

    init(viewModel: OmakaseViewModel) {
        self.viewModel = viewModel
        _artistInput = State(initialValue: viewModel.savedArtist?.artistQuery ?? "")
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 24) {
                Spacer()

                Text("Enter the artist")
                    .font(.system(size: 38, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))

                TextField("e.g. TOMOO / 緑黄色社会", text: $artistInput)
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveImmediately()
                    }
                    .onChange(of: artistInput) { newValue in
                        scheduleDebouncedSave(for: newValue)
                    }
                    .onChange(of: isTextFieldFocused) { focused in
                        if !focused {
                            saveImmediately()
                        }
                    }

                if viewModel.isResolvingArtist {
                    ProgressView("saving artist…")
                        .foregroundStyle(.white.opacity(0.95))
                        .tint(.white)
                }

                if let inputErrorMessage = viewModel.inputErrorMessage {
                    Text(inputErrorMessage)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .onDisappear {
            debounceTask?.cancel()
        }
    }

    private func scheduleDebouncedSave(for query: String) {
        debounceTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await viewModel.resolveAndSaveArtist(query: query)
        }
    }

    private func saveImmediately() {
        debounceTask?.cancel()
        Task {
            await viewModel.resolveAndSaveArtist(query: artistInput)
        }
    }
}
