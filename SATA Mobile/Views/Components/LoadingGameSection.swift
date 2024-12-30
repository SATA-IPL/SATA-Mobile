import SwiftUI

struct LoadingGameSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    loadingGameCard
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadingGameCard: some View {
        ShimmerLoadingView()
            .frame(height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.thinMaterial, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 3)
    }
}
