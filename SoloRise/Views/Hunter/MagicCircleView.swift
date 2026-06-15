import SwiftUI

struct MagicCircleView: View {
    let rank: HunterRank
    @State private var rotation: Double = 0
    @State private var rotation2: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(rank.color.opacity(0.04))
                .frame(width: 260, height: 260)
                .scaleEffect(pulseScale)

            // Outermost ring — slow rotation
            Circle()
                .stroke(rank.color.opacity(0.15), lineWidth: 1)
                .frame(width: 240, height: 240)

            // Rune tick marks on outer ring
            ForEach(0..<24, id: \.self) { i in
                Rectangle()
                    .fill(rank.color.opacity(i % 3 == 0 ? 0.6 : 0.2))
                    .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? 10 : 6)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(i) * 15))
            }

            // Outer rotating ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [rank.color.opacity(0), rank.color.opacity(0.8), rank.color.opacity(0)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotation))

            // Counter-rotating inner ring
            Circle()
                .trim(from: 0.1, to: 0.6)
                .stroke(
                    AngularGradient(
                        colors: [rank.color.opacity(0), rank.color.opacity(0.5), rank.color.opacity(0)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotation2))

            // Inner tick marks
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(rank.color.opacity(0.3))
                    .frame(width: 1, height: 6)
                    .offset(y: -75)
                    .rotationEffect(.degrees(Double(i) * 30 + rotation * 0.3))
            }

            // Diamond points (4 cardinal directions)
            ForEach(0..<4, id: \.self) { i in
                diamondPoint
                    .rotationEffect(.degrees(Double(i) * 90 + rotation * 0.2))
            }

            // Inner solid circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [rank.color.opacity(0.15), rank.color.opacity(0.02)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)

            Circle()
                .stroke(rank.color.opacity(0.4), lineWidth: 1)
                .frame(width: 110, height: 110)
                .shadow(color: rank.color.opacity(0.6), radius: 6)

            // Center figure — stylized hunter silhouette
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(rank.color.opacity(0.9))
                    .frame(width: 12, height: 12)
                    .shadow(color: rank.color, radius: 4)

                // Body
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [rank.color.opacity(0.9), rank.color.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 22)

                // Cape spread
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: -16, y: 18))
                    p.addLine(to: CGPoint(x: 16, y: 18))
                    p.closeSubpath()
                }
                .fill(rank.color.opacity(0.5))
                .frame(width: 32, height: 18)
            }
            .shadow(color: rank.color.opacity(0.8), radius: 8)
            .scaleEffect(pulseScale * 0.98)

            // Rank label below circle
            Text("RANK \(rank.label)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(rank.color.opacity(0.7))
                .tracking(4)
                .offset(y: 145)
        }
        .frame(width: 260, height: 300)
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation2 = -360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
                glowOpacity = 0.7
            }
        }
    }

    private var diamondPoint: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: -6))
            p.addLine(to: CGPoint(x: 3, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 6))
            p.addLine(to: CGPoint(x: -3, y: 0))
            p.closeSubpath()
        }
        .fill(rank.color.opacity(0.8))
        .frame(width: 6, height: 12)
        .offset(y: -98)
        .shadow(color: rank.color, radius: 4)
    }
}
