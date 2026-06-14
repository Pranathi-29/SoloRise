import SwiftUI
import UIKit

// MARK: - Solo Leveling System color palette
extension Color {
    static let sysBG         = Color(hex: "#050810")
    static let sysPanel      = Color(hex: "#080D1A")
    static let sysCard       = Color(hex: "#0C1220")
    static let sysCard2      = Color(hex: "#101828")
    static let sysBorder     = Color(hex: "#1A2540")
    static let sysBorder2    = Color(hex: "#243050")

    static let sysBlue       = Color(hex: "#4A9EFF")
    static let sysBlueDim    = Color(hex: "#1A3A6A")
    static let sysCyan       = Color(hex: "#00D4FF")
    static let sysPurple     = Color(hex: "#7B5CE4")
    static let sysPurpleDim  = Color(hex: "#3A2880")
    static let sysGold       = Color(hex: "#FFD700")
    static let sysGoldDim    = Color(hex: "#6A5400")
    static let sysGreen      = Color(hex: "#39FF6A")
    static let sysRed        = Color(hex: "#FF4060")

    static let textPrimary   = Color(hex: "#C8D8FF")
    static let textSecondary = Color(hex: "#5A7AAA")
    static let textDim       = Color(hex: "#2A3A5A")

    // Rank colours
    static let rankE = Color(hex: "#888888")
    static let rankD = Color(hex: "#4A9EFF")
    static let rankC = Color(hex: "#39FF6A")
    static let rankB = Color(hex: "#FFD700")
    static let rankA = Color(hex: "#FF6B35")
    static let rankS = Color(hex: "#FF4060")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb & 0xFF) / 255
        )
    }
}

extension HunterRank {
    var color: Color {
        switch self {
        case .e: return .rankE
        case .d: return .rankD
        case .c: return .rankC
        case .b: return .rankB
        case .a: return .rankA
        case .s: return .rankS
        }
    }
}

// MARK: - Haptics
struct Haptic {
    static func questComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func rankUp() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { g.impactOccurred() }
    }
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}