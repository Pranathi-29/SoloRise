import Foundation
import SwiftData

// A real-life reward the user pre-commits to, unlocked by reaching a rank and
// "bought" by spending the gold they've saved by then. Stored encoded on Hunter.
struct RankReward: Codable, Identifiable {
    var rankRaw: Int    // the rank that unlocks it: 1=D, 2=C, 3=B, 4=A, 5=S
    var title: String
    var goldCost: Int
    var claimed: Bool
    var id: Int { rankRaw }
}

enum HunterRank: Int, Codable, CaseIterable {
    case e = 0, d, c, b, a, s

    var label: String { ["E","D","C","B","A","S"][rawValue] }
    var title: String { ["Shadow Fragment","Shadow Scout","Shadow Rogue","Shadow Knight","Shadow Commander","Eclipse General"][rawValue] }

    // Minimum per-stat required to rank up FROM this rank.
    // Tuned for ~1 year E→S at 80% consistency (each quest = +1/stat per day).
    var statRequired: Int { [25, 55, 110, 190, 300, 9999][rawValue] }

    var next: HunterRank? { HunterRank(rawValue: rawValue + 1) }
}

@Model
final class Hunter {
    var name: String
    var rankRaw: Int
    var gold: Int
    var streak: Int
    var streakShields: Int = 0
    var bossClaimMask: Int = 0   // bitmask of bosses whose gold reward has been claimed
    var gateClaimMask: Int = 0   // bitmask of gates whose gold reward has been claimed
    var lastActiveDate: Date?

    // First-launch onboarding (name + real-life rewards) completed?
    var hasOnboarded: Bool = false
    // Real-life rewards, JSON-encoded (kept as Data so SwiftData persists it simply)
    var rankRewardsData: Data = Data()

    var rankRewards: [RankReward] {
        get { (try? JSONDecoder().decode([RankReward].self, from: rankRewardsData)) ?? [] }
        set { rankRewardsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // Default reward slots — one per rank-up, with gold costs that track how much
    // gold you'll have saved by the time you reach each rank (always affordable).
    static func defaultRewards() -> [RankReward] {
        [
            .init(rankRaw: 1, title: "", goldCost: 400,  claimed: false),
            .init(rankRaw: 2, title: "", goldCost: 800,  claimed: false),
            .init(rankRaw: 3, title: "", goldCost: 1600, claimed: false),
            .init(rankRaw: 4, title: "", goldCost: 3000, claimed: false),
            .init(rankRaw: 5, title: "", goldCost: 5000, claimed: false),
        ]
    }

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

    // Total power = sum of all stats (flavor number shown on the status bar)
    var power: Int { statSTR + statINT + statVIT + statWIS }

    // The stat currently gating the next rank-up (the slowest one)
    var limitingStat: Int { min(statSTR, statINT, statVIT, statWIS) }

    // Progress toward next rank (0.0 to 1.0), driven by the limiting stat
    // so the bar fills exactly in step with the all-4-stats gate.
    var rankProgress: Double {
        guard let _ = rank.next else { return 1.0 }
        let required = rank.statRequired
        // Floor of the current rank band: the threshold that got us here (start = 10 at rank E)
        let base = rank.rawValue > 0 ? HunterRank(rawValue: rank.rawValue - 1)!.statRequired : 10
        let progress = Double(limitingStat - base) / Double(required - base)
        return max(0, min(1, progress))
    }

    // Per-stat requirement for current rank-up
    var statRequiredForNextRank: Int { rank.statRequired }

    init(name: String = "Shadow Hunter") {
        self.name = name
        self.rankRaw = HunterRank.e.rawValue
        self.gold = 0
        self.streak = 0
        self.streakShields = 0
        self.bossClaimMask = 0
        self.gateClaimMask = 0
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
