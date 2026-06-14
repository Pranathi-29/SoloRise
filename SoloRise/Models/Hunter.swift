import Foundation
import SwiftData

// Rank progression: E(0) D(1) C(2) B(3) A(4) S(5)
enum HunterRank: Int, Codable, CaseIterable {
    case e = 0, d, c, b, a, s

    var label: String { ["E","D","C","B","A","S"][rawValue] }
    var title: String { ["E-Rank Hunter","D-Rank Hunter","C-Rank Hunter","B-Rank Hunter","A-Rank Hunter","National Level Hunter"][rawValue] }
    var xpRequired: Int { [200, 350, 550, 800, 1200, 99999][rawValue] }

    var next: HunterRank? { HunterRank(rawValue: rawValue + 1) }
}

@Model
final class Hunter {
    var name: String
    var rankRaw: Int
    var xp: Int
    var gold: Int
    var streak: Int
    var lastActiveDate: Date?

    // Stats
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

    init(name: String = "Sung Jin-Woo") {
        self.name = name
        self.rankRaw = HunterRank.e.rawValue
        self.xp = 0
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