import Foundation
import SwiftData

enum HunterRank: Int, Codable, CaseIterable {
    case e = 0, d, c, b, a, s

    var label: String { ["E","D","C","B","A","S"][rawValue] }
    var title: String { ["Shadow Fragment","Shadow Scout","Shadow Rogue","Shadow Knight","Shadow Commander","Eclipse General"][rawValue] }

    // Minimum total power (STR+INT+VIT+WIS) required to rank up FROM this rank
    var powerRequired: Int { [80, 160, 260, 380, 520, 99999][rawValue] }

    // Minimum per-stat required to rank up FROM this rank
    var statRequired: Int { [20, 40, 65, 95, 130, 9999][rawValue] }

    var next: HunterRank? { HunterRank(rawValue: rawValue + 1) }
}

@Model
final class Hunter {
    var name: String
    var rankRaw: Int
    var gold: Int
    var streak: Int
    var lastActiveDate: Date?

    // Stats — these now drive everything
    var statSTR: Int
    var statINT: Int
    var statVIT: Int
    var statWIS: Int

    // Cumulative counters (for gate/boss unlock checks)
    var totalWorkouts: Int
    var totalStudySessions: Int
    var totalHealthyDays: Int
    var totalReadingSessions: Int
    var totalRecoveryDays: Int

    var rank: HunterRank {
        get { HunterRank(rawValue: rankRaw) ?? .e }
        set { rankRaw = newValue.rawValue }
    }

    // Total power = sum of all stats
    var power: Int { statSTR + statINT + statVIT + statWIS }

    // Progress toward next rank (0.0 to 1.0)
    var rankProgress: Double {
        guard let _ = rank.next else { return 1.0 }
        let required = rank.powerRequired
        // For rank E, base is 40 (4 stats × 10 starting value) so the bar starts at 0%
        let base = rank.rawValue > 0 ? HunterRank(rawValue: rank.rawValue - 1)!.powerRequired : 40
        let progress = Double(power - base) / Double(required - base)
        return max(0, min(1, progress))
    }

    // Per-stat requirement for current rank-up
    var statRequiredForNextRank: Int { rank.statRequired }

    init(name: String = "Shadow Hunter") {
        self.name = name
        self.rankRaw = HunterRank.e.rawValue
        self.gold = 0
        self.streak = 0
        self.statSTR = 10
        self.statINT = 10
        self.statVIT = 10
        self.statWIS = 10
        self.totalWorkouts = 0
        self.totalStudySessions = 0
        self.totalHealthyDays = 0
        self.totalReadingSessions = 0
        self.totalRecoveryDays = 0
    }
}
