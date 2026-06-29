import SwiftUI

// MARK: - Single rank image view
// Add rank_e.png … rank_s.png to Assets.xcassets
struct HunterRankImage: View {
    let rank: HunterRank

    private var imageName: String {
        switch rank {
        case .e: return "rank_e"
        case .d: return "rank_d"
        case .c: return "rank_c"
        case .b: return "rank_b"
        case .a: return "rank_a"
        case .s: return "rank_s"
        }
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .clipped()
            .allowsHitTesting(false)
            .transition(.opacity.combined(with: .scale(scale: 1.02)))
            .id(rank.rawValue) // triggers transition on rank change
    }
}

// MARK: - Rank-up overlay character display
struct RankUpCharacterView: View {
    let rank: HunterRank

    var body: some View {
        ZStack {
            // Glow behind image
            RoundedRectangle(cornerRadius: 0)
                .fill(rank.color.opacity(0.12))
                .blur(radius: 20)

            HunterRankImage(rank: rank)
                .frame(width: 240, height: 320)
                .clipped()
                .overlay(
                    // vignette edges
                    LinearGradient(
                        colors: [
                            rank.color.opacity(0.0),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 60)
                }
        }
        .frame(width: 240, height: 320)
    }
}
