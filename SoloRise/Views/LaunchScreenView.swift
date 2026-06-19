import SwiftUI

struct LaunchScreenView: View {
    @State private var textOpacity: Double = 0
    @State private var lineWidth: CGFloat = 0
    @State private var dotsVisible = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#07050F").ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Top glow line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(hex: "#A78BFF"), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: lineWidth, height: 1)
                    .animation(.easeOut(duration: 0.8), value: lineWidth)

                VStack(spacing: 8) {
                    Text("SYSTEM")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: "#A78BFF"))
                        .tracking(10)
                        .shadow(color: Color(hex: "#A78BFF").opacity(0.6), radius: 12)

                    if dotsVisible {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color(hex: "#A78BFF").opacity(0.7))
                                    .frame(width: 5, height: 5)
                                    .scaleEffect(dotsVisible ? 1 : 0)
                                    .animation(
                                        .easeInOut(duration: 0.4)
                                        .repeatForever()
                                        .delay(Double(i) * 0.15),
                                        value: dotsVisible
                                    )
                            }
                        }
                    }

                    Text("INITIALIZING...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "#5A7AAA"))
                        .tracking(4)
                }
                .opacity(textOpacity)

                // Bottom glow line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(hex: "#7C3AED").opacity(0.6), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: lineWidth, height: 1)
                    .animation(.easeOut(duration: 0.8), value: lineWidth)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { textOpacity = 1 }
            lineWidth = 280
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) { dotsVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.4)) { textOpacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onComplete() }
            }
        }
    }
}
