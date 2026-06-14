import SwiftUI

struct StatBar: View {
    let label: String
    let value: Int
    let color: Color
    var maxValue: Int = 50

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(color)
                .frame(width: 30, alignment: .leading)

            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 36, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.sysBorder)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(value, maxValue)) / CGFloat(maxValue))
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }
}