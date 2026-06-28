import SwiftUI

// MARK: - Character Card (Hunter tab)
struct HunterCharacterCard: View {
    let store: HunterStore

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("HUNTER PROFILE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.sysBlue)
                Spacer()
                Text(store.hunter.rank.title.uppercased())
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(store.hunter.rank.color)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.sysPanel)

            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, store.hunter.rank.color.opacity(0.7), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            // Image panel
            ZStack(alignment: .bottom) {
                HunterRankImage(rank: store.hunter.rank)

                // Bottom fade + rank label
                LinearGradient(
                    colors: [.clear, Color.sysCard.opacity(0.95)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 80)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.hunter.rank.label + " RANK")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(store.hunter.rank.color)
                            .shadow(color: store.hunter.rank.color.opacity(0.9), radius: 8)
                        Text(rankSubtitle(store.hunter.rank))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                            .tracking(2)
                    }
                    Spacer()
                    // XP to next rank
                    if let next = store.hunter.rank.next {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NEXT: \(next.label) RANK")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(Color.textDim)
                        }
                    } else {
                        Text("MAX RANK")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(store.hunter.rank.color)
                            .shadow(color: store.hunter.rank.color, radius: 6)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .background(Color.sysCard)
        }
        .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
    }

    private func rankSubtitle(_ rank: HunterRank) -> String {
        switch rank {
        case .e: return "SHADOW FRAGMENT"
        case .d: return "SHADOW SCOUT"
        case .c: return "SHADOW ROGUE"
        case .b: return "SHADOW KNIGHT"
        case .a: return "SHADOW COMMANDER"
        case .s: return "ECLIPSE GENERAL"
        }
    }
}

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
