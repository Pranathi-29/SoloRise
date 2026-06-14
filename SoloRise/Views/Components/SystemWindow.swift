import SwiftUI

/// The glowing-border "System" panel used throughout the UI
struct SystemWindow<Content: View>: View {
    let title: String
    var badge: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.sysBlue)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.sysPanel)

            // Top glow line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .sysBlue.opacity(0.7), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            content()
                .padding(12)
        }
        .background(Color.sysCard)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.sysBorder2, lineWidth: 1)
        )
    }
}