import Foundation
import SwiftData
import SwiftUI

@Observable
final class HunterStore {
    var hunter: Hunter
    var todayLog: DailyLog
    var pendingRankUp: HunterRank? = nil
    var lastClearedQuest: QuestDefinition? = nil

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Load or create hunter
        let hunterDesc = FetchDescriptor<Hunter>()
        if let existing = try? modelContext.fetch(hunterDesc).first {
            self.hunter = existing
        } else {
            let h = Hunter()
            modelContext.insert(h)
            self.hunter = h
        }

        // Load or create today's log
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = Self.log(for: today, in: modelContext) {
            self.todayLog = existing
        } else {
            let log = DailyLog(date: today)
            modelContext.insert(log)
            self.todayLog = log
        }

        checkStreak()
    }

    // MARK: - Called when app becomes active (scenePhase check)
    func onAppActive() {
        let today = Calendar.current.startOfDay(for: .now)
        guard !Calendar.current.isDate(todayLog.date, inSameDayAs: today) else { return }

        if let existing = Self.log(for: today, in: modelContext) {
            todayLog = existing
        } else {
            let newLog = DailyLog(date: today)
            modelContext.insert(newLog)
            todayLog = newLog
        }
        checkStreak()
        save()
    }

    // MARK: - Quest completion
    @discardableResult
    func completeQuest(_ id: QuestID) -> Bool {
        guard !isComplete(id),
              let def = QuestDefinition.all.first(where: { $0.questID == id }) else {
            return false
        }

        setDone(id, true)

        for reward in def.rewards {
            if reward.type == .xp {
                addXP(reward.value + xpBuffBonus(for: def, baseXP: reward.value))
            } else {
                apply(reward: reward)
            }
        }

        switch id {
        case .workout:   hunter.totalWorkouts += 1
        case .study:     hunter.totalStudySessions += 1
        case .nutrition: hunter.totalHealthyDays += 1
        case .reading:   hunter.totalReadingSessions += 1
        case .recovery:  hunter.totalRecoveryDays += 1
        }

        lastClearedQuest = def
        save()
        return true
    }

    func uncompleteQuest(_ id: QuestID) {
        guard isComplete(id) else { return }
        let def = QuestDefinition.all.first { $0.questID == id }!
        setDone(id, false)
        for reward in def.rewards {
            switch reward.type {
            case .str:  hunter.statSTR = max(10, hunter.statSTR - reward.value)
            case .int:  hunter.statINT = max(10, hunter.statINT - reward.value)
            case .vit:  hunter.statVIT = max(10, hunter.statVIT - reward.value)
            case .wis:  hunter.statWIS = max(10, hunter.statWIS - reward.value)
            case .gold: hunter.gold = max(0, hunter.gold - reward.value)
            case .xp:   hunter.xp = max(0, hunter.xp - reward.value)
            }
        }
        switch id {
        case .workout:   hunter.totalWorkouts = max(0, hunter.totalWorkouts - 1)
        case .study:     hunter.totalStudySessions = max(0, hunter.totalStudySessions - 1)
        case .nutrition: hunter.totalHealthyDays = max(0, hunter.totalHealthyDays - 1)
        case .reading:   hunter.totalReadingSessions = max(0, hunter.totalReadingSessions - 1)
        case .recovery:  hunter.totalRecoveryDays = max(0, hunter.totalRecoveryDays - 1)
        }
        save()
    }

    func toggleBuff(_ keyPath: WritableKeyPath<DailyLog, Bool>) {
        todayLog[keyPath: keyPath].toggle()
        save()
    }

    // MARK: - Helpers
    func isComplete(_ id: QuestID) -> Bool {
        switch id {
        case .workout:   return todayLog.workoutDone
        case .nutrition: return todayLog.nutritionDone
        case .study:     return todayLog.studyDone
        case .reading:   return todayLog.readingDone
        case .recovery:  return todayLog.recoveryDone
        }
    }

    var questProgress: (done: Int, total: Int) {
        (todayLog.completedCount, 5)
    }

    var hasPerfectDay: Bool {
        if todayLog.allComplete { return true }

        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in
                log.workoutDone && log.nutritionDone && log.studyDone &&
                log.readingDone && log.recoveryDone
            }
        )
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    // MARK: - All past logs (for calendar)
    func recentLogs(days: Int) -> [DailyLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        var desc = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in log.date >= cutoff },
            sortBy: [SortDescriptor(\.date)]
        )
        desc.fetchLimit = days + 1
        return (try? modelContext.fetch(desc)) ?? []
    }

    // MARK: - Private
    private func setDone(_ id: QuestID, _ val: Bool) {
        switch id {
        case .workout:   todayLog.workoutDone = val
        case .nutrition: todayLog.nutritionDone = val
        case .study:     todayLog.studyDone = val
        case .reading:   todayLog.readingDone = val
        case .recovery:  todayLog.recoveryDone = val
        }
    }

    private func apply(reward: QuestDefinition.Reward) {
        switch reward.type {
        case .str:  hunter.statSTR += reward.value
        case .int:  hunter.statINT += reward.value
        case .vit:  hunter.statVIT += reward.value
        case .wis:  hunter.statWIS += reward.value
        case .gold: hunter.gold += reward.value
        case .xp:   addXP(reward.value)
        }
    }

    private func reverseReward(reward: QuestDefinition.Reward) {
        switch reward.type {
        case .str:  hunter.statSTR = max(10, hunter.statSTR - reward.value)
        case .int:  hunter.statINT = max(10, hunter.statINT - reward.value)
        case .vit:  hunter.statVIT = max(10, hunter.statVIT - reward.value)
        case .wis:  hunter.statWIS = max(10, hunter.statWIS - reward.value)
        case .gold: hunter.gold = max(0, hunter.gold - reward.value)
        case .xp:   hunter.xp = max(0, hunter.xp - reward.value)
        }
    }

    private func xpBuffBonus(for quest: QuestDefinition, baseXP: Int) -> Int {
        let rewardTypes = quest.rewards.map(\.type)
        var bonusRate = 0.0

        if rewardTypes.contains(.vit) {
            if todayLog.supplementsBuff { bonusRate += 0.05 }
            if todayLog.waterBuff { bonusRate += 0.08 }
        }
        if rewardTypes.contains(.str), todayLog.proteinBuff {
            bonusRate += 0.06
        }

        return Int((Double(baseXP) * bonusRate).rounded())
    }

    private func addXP(_ amount: Int) {
        hunter.xp += amount
        var latestRankUp: HunterRank?

        while let next = hunter.rank.next, hunter.xp >= hunter.rank.xpRequired {
            let required = hunter.rank.xpRequired
            hunter.xp -= required
            hunter.rank = next
            hunter.gold += 50
            latestRankUp = next
        }

        pendingRankUp = latestRankUp ?? pendingRankUp
    }

    private func checkStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        guard let last = hunter.lastActiveDate else {
            // First ever launch
            hunter.lastActiveDate = today
            hunter.streak = 0
            save()
            return
        }

        let lastDay = cal.startOfDay(for: last)
        let daysDiff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0

        switch daysDiff {
        case 0:
            // Same day — no change
            break
        case 1:
            // Consecutive day — increment streak
            hunter.streak += 1
            hunter.lastActiveDate = today
        default:
            // Missed days — reset streak
            hunter.streak = 0
            hunter.lastActiveDate = today
        }
        save()
    }

    private func save() {
        try? modelContext.save()
    }

    private static func log(for date: Date, in modelContext: ModelContext) -> DailyLog? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }

        var descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in log.date >= start && log.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
