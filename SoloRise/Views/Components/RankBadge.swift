import SwiftUI

struct RankBadge: View {
    let rank: HunterRank
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Rectangle()
                .fill(rank.color.opacity(0.08))
                .overlay(
                    Rectangle().stroke(rank.color, lineWidth: 2)
                )

            Text(rank.label)
                .font(.system(size: size * 0.5, weight: .black, design: .monospaced))
                .foregroundStyle(rank.color)
        }
        .frame(width: size, height: size)
        .shadow(color: rank.color.opacity(0.5), radius: 8)
    }
}