import SwiftUI

struct SysSection: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(Color.sysBlue)
            Rectangle()
                .fill(Color.sysBorder)
                .frame(height: 1)
        }
        .padding(.top, 4)
    }
}