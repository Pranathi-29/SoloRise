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

// A logged answer to "why haven't you done this quest lately?" — feeds the Insights view.
struct MissReason: Codable, Identifiable {
    var id: UUID = UUID()
    var questRaw: String
    var date: Date
    var reason: String
    var note: String
}

// A daily reflection — "what went well / what got in the way" — accumulates as input
// for the weekly AI coaching summary (alongside the logged miss reasons).
struct Reflection: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var wentWell: String
    var gotInWay: String
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
    var maxStreak: Int = 0       // longest streak ever reached (for Insights)
    var streakShields: Int = 0
    var bossClaimMask: Int = 0   // bitmask of bosses whose gold reward has been claimed
    var gateClaimMask: Int = 0   // bitmask of gates whose gold reward has been claimed
    var lastActiveDate: Date?

    // Per-quest "why I missed" tracking, all JSON-encoded (keyed by QuestID.rawValue):
    var questLastDoneData: Data = Data()    // [String: Date] — last completion per quest
    var questLastNudgedData: Data = Data()  // [String: Date] — last miss-nudge per quest
    var missLogData: Data = Data()          // [MissReason] — logged skip reasons

    var questLastDone: [String: Date] {
        get { (try? JSONDecoder().decode([String: Date].self, from: questLastDoneData)) ?? [:] }
        set { questLastDoneData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var questLastNudged: [String: Date] {
        get { (try? JSONDecoder().decode([String: Date].self, from: questLastNudgedData)) ?? [:] }
        set { questLastNudgedData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var missLog: [MissReason] {
        get { (try? JSONDecoder().decode([MissReason].self, from: missLogData)) ?? [] }
        set { missLogData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // Daily reflections + the latest weekly AI coaching summary
    var reflectionsData: Data = Data()
    var coachingSummary: String = ""
    var coachingDate: Date?

    var reflections: [Reflection] {
        get { (try? JSONDecoder().decode([Reflection].self, from: reflectionsData)) ?? [] }
        set { reflectionsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

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
