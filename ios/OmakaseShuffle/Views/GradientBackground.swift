import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.72, green: 0.92, blue: 0.88),
                Color(red: 0.50, green: 0.80, blue: 0.90),
                Color(red: 0.37, green: 0.67, blue: 0.87)
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
