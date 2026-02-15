import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.53, blue: 0.62),
                Color(red: 0.91, green: 0.62, blue: 0.46),
                Color(red: 0.75, green: 0.40, blue: 0.24)
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.22), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
        )
        .ignoresSafeArea()
    }
}

