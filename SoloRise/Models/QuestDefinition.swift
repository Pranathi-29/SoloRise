import Foundation
import SwiftUI

enum QuestID: String, CaseIterable, Identifiable {
    case workout, nutrition, study, reading, recovery
    var id: String { rawValue }
}

// Preset answers for the "why did I miss" nudge.
enum MissReasonOption: String, CaseIterable, Identifiable {
    case tooBusy = "Too busy"
    case lowEnergy = "Low energy"
    case forgot = "Forgot"
    case unwell = "Unwell"
    case lostMotivation = "Lost motivation"
    case other = "Other"
    var id: String { rawValue }
}

struct QuestDefinition: Identifiable {
    var id: String { questID.rawValue }
    let questID: QuestID
    let sfSymbol: String
    let name: String
    let flavor: String
    let rewards: [Reward]

    struct Reward {
        let type: RewardType
        let value: Int
        var label: String { "+\(value) \(type.label)" }
    }

    enum RewardType: Equatable {
        case str, int, vit, wis, gold
        var label: String {
            switch self {
            case .str:  return "STR"
            case .int:  return "INT"
            case .vit:  return "VIT"
            case .wis:  return "WIS"
            case .gold: return "Gold"
            }
        }
    }

    static let all: [QuestDefinition] = [
        .init(questID: .workout,
              sfSymbol: "dumbbell.fill",
              name: "Physical Training",
              flavor: "The body is a weapon. Sharpen it.",
              rewards: [.init(type: .str, value: 1), .init(type: .gold, value: 5)]),

        .init(questID: .nutrition,
              sfSymbol: "carrot.fill",
              name: "Nutrition",
              flavor: "Fuel the machine.",
              rewards: [.init(type: .vit, value: 1), .init(type: .gold, value: 5)]),

        .init(questID: .study,
              sfSymbol: "chart.line.uptrend.xyaxis",
              name: "Career Growth",
              flavor: "Sharpen the blade that carves your future.",
              rewards: [.init(type: .int, value: 1), .init(type: .gold, value: 8)]),

        .init(questID: .reading,
              sfSymbol: "brain.head.profile",
              name: "Mind Training",
              flavor: "Every page is a level gained.",
              rewards: [.init(type: .wis, value: 1), .init(type: .gold, value: 5)]),

        .init(questID: .recovery,
              sfSymbol: "moon.stars.fill",
              name: "Recovery",
              flavor: "Even the Shadow Monarch rests.",
              rewards: [.init(type: .vit, value: 1), .init(type: .gold, value: 4)]),
    ]
}

extension QuestID {
    var color: Color {
        switch self {
        case .workout:   return .sysRed
        case .nutrition: return .sysGreen
        case .study:     return .sysBlue
        case .reading:   return .sysPurple
        case .recovery:  return Color(hex: "#5B8CFF")
        }
    }
}

extension QuestDefinition.RewardType {
    var color: Color {
        switch self {
        case .str:  return .sysRed
        case .int:  return .sysBlue
        case .vit:  return .sysGreen
        case .wis:  return .sysPurple
        case .gold: return .sysGold
        }
    }
}
