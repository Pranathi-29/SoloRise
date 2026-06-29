import Foundation
import SwiftData
import SwiftUI
import UserNotifications

@Observable
final class HunterStore {
    var hunter: Hunter
    var todayLog: DailyLog
    var pendingRankUp: HunterRank? = nil
    var refreshTick: Int = 0

    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        let hunterDesc = FetchDescriptor<Hunter>()
        if let existing = try? modelContext.fetch(hunterDesc).first {
            self.hunter = existing
        } else {
            let h = Hunter()
            modelContext.insert(h)
            self.hunter = h
        }

        let today = Calendar.current.startOfDay(for: .now)
        if let existing = Self.log(for: today, in: modelContext) {
            self.todayLog = existing
        } else {
            let log = DailyLog(date: today)
            modelContext.insert(log)
            self.todayLog = log
        }

        checkStreak()

        // Ensure the 5 reward slots always exist (onboarding fills in their titles).
        if hunter.rankRewards.isEmpty {
            hunter.rankRewards = Hunter.defaultRewards()
            save()
        }

        // Returning (already-onboarded) users: refresh their reminders on launch.
        // New users get the permission prompt right after onboarding's "BEGIN".
        if hunter.hasOnboarded {
            NotificationManager.requestAuthorization()
            refreshNotifications()
        }
    }

    // MARK: - Notifications
    func refreshNotifications() {
        NotificationManager.scheduleMorningReminder()
        NotificationManager.scheduleStreakWarnings()
        updateTodayStreakWarning()
    }

    /// Cancels tonight's streak warning once the day is complete; re-arms it otherwise.
    func updateTodayStreakWarning() {
        if todayLog.allComplete {
            NotificationManager.cancelWarning(for: .now)
        } else {
            NotificationManager.scheduleWarning(for: .now)
        }
    }

    // MARK: - Onboarding & real-life rewards
    func completeOnboarding(name: String, rewardTitles: [String]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { hunter.name = trimmed }
        var rewards = Hunter.defaultRewards()
        for i in rewards.indices where i < rewardTitles.count {
            rewards[i].title = rewardTitles[i].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        hunter.rankRewards = rewards
        hunter.hasOnboarded = true
        refreshTick += 1
        save()

        NotificationManager.requestAuthorization()
        refreshNotifications()
    }

    func setRewardTitle(rankRaw: Int, title: String) {
        var rewards = hunter.rankRewards
        guard let idx = rewards.firstIndex(where: { $0.rankRaw == rankRaw }) else { return }
        rewards[idx].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        hunter.rankRewards = rewards
        refreshTick += 1
        save()
    }

    func canClaim(_ reward: RankReward) -> Bool {
        !reward.claimed
            && !reward.title.isEmpty
            && hunter.rank.rawValue >= reward.rankRaw
            && hunter.gold >= reward.goldCost
    }

    func isUnlocked(_ reward: RankReward) -> Bool {
        hunter.rank.rawValue >= reward.rankRaw
    }

    func claimReward(_ reward: RankReward) {
        guard canClaim(reward) else { return }
        var rewards = hunter.rankRewards
        guard let idx = rewards.firstIndex(where: { $0.rankRaw == reward.rankRaw }) else { return }
        rewards[idx].claimed = true
        hunter.rankRewards = rewards
        hunter.gold = max(0, hunter.gold - reward.goldCost)
        refreshTick += 1
        save()
    }

    func reward(forRank rank: HunterRank) -> RankReward? {
        hunter.rankRewards.first { $0.rankRaw == rank.rawValue }
    }

    // MARK: - App active
    func onAppActive() {
        let today = Calendar.current.startOfDay(for: .now)
        if !Calendar.current.isDate(todayLog.date, inSameDayAs: today) {
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
        if hunter.hasOnboarded { refreshNotifications() }
    }

    // MARK: - Quest completion
    @discardableResult
    func completeQuest(_ id: QuestID) -> Bool {
        guard !isComplete(id),
              let def = QuestDefinition.all.first(where: { $0.questID == id }) else {
            return false
        }

        // The streak is earned by completing a quest — so the *first* completion
        // of the day is what advances it.
        let isFirstOfDay = todayLog.completedCount == 0

        setDone(id, true)

        for reward in def.rewards {
            apply(reward: reward)
        }

        switch id {
        case .workout:   hunter.totalWorkouts += 1
        case .study:     hunter.totalStudySessions += 1
        case .nutrition: hunter.totalHealthyDays += 1
        case .reading:   hunter.totalReadingSessions += 1
        case .recovery:  hunter.totalRecoveryDays += 1
        }

        if isFirstOfDay { registerActiveDay() }
        checkRankUp()
        checkBosses()
        checkGates()
        updateTodayStreakWarning()
        save()
        return true
    }

    // Award a gate's one-time gold reward the first time it's cleared.
    private func checkGates() {
        for (i, gate) in GateData.all(for: hunter).enumerated() {
            let bit = 1 << i
            if gate.isCleared && gate.goldReward > 0 && (hunter.gateClaimMask & bit) == 0 {
                hunter.gateClaimMask |= bit
                hunter.gold += gate.goldReward
            }
        }
    }

    // Advances the streak when the first quest of a day is completed. Shields bridge
    // any fully-missed days since the last active day; an un-bridgeable gap restarts at 1.
    private func registerActiveDay() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let last = hunter.lastActiveDate else {
            hunter.streak = 1
            hunter.lastActiveDate = today
            return
        }
        let lastDay = cal.startOfDay(for: last)
        let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
        guard diff > 0 else { return }   // already counted as active today
        let missed = diff - 1
        if missed == 0 {
            hunter.streak += 1
        } else if hunter.streakShields >= missed {
            hunter.streakShields -= missed
            hunter.streak += 1
        } else {
            hunter.streak = 1
        }
        hunter.lastActiveDate = today
    }

    // Award a boss's gold once, the first time its goal is met.
    private func checkBosses() {
        for (i, boss) in BossDefinition.all.enumerated() {
            let bit = 1 << i
            if (hunter.bossClaimMask & bit) == 0 && boss.current(for: hunter) >= boss.threshold {
                hunter.bossClaimMask |= bit
                hunter.gold += boss.goldReward
            }
        }
    }

    func uncompleteQuest(_ id: QuestID) {
        guard isComplete(id) else { return }
        let def = QuestDefinition.all.first { $0.questID == id }!
        setDone(id, false)
        for reward in def.rewards {
            reverseReward(reward: reward)
        }
        switch id {
        case .workout:   hunter.totalWorkouts = max(0, hunter.totalWorkouts - 1)
        case .study:     hunter.totalStudySessions = max(0, hunter.totalStudySessions - 1)
        case .nutrition: hunter.totalHealthyDays = max(0, hunter.totalHealthyDays - 1)
        case .reading:   hunter.totalReadingSessions = max(0, hunter.totalReadingSessions - 1)
        case .recovery:  hunter.totalRecoveryDays = max(0, hunter.totalRecoveryDays - 1)
        }
        checkRankDown()
        updateTodayStreakWarning()
        refreshTick += 1
        save()
    }

    func toggleBuff(_ keyPath: WritableKeyPath<DailyLog, Bool>) {
        todayLog[keyPath: keyPath].toggle()
        updateShield()
        refreshTick += 1
        save()
    }

    // Bonus quests don't touch stats. Completing all 3 in a day banks one
    // Streak Shield (capped at 3). Latched per-day so toggling off won't revoke it.
    static let maxShields = 3
    private func updateShield() {
        let allBonusDone = todayLog.waterBuff && todayLog.supplementsBuff && todayLog.proteinBuff
        if allBonusDone && !todayLog.shieldEarned {
            todayLog.shieldEarned = true
            hunter.streakShields = min(Self.maxShields, hunter.streakShields + 1)
        }
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

    // MARK: - Rank up check (stat-driven)
    private func checkRankUp() {
        guard let next = hunter.rank.next else { return }
        let req = hunter.rank.statRequired

        // All stats must meet the per-stat minimum
        let statsReady = hunter.statSTR >= req &&
                         hunter.statINT >= req &&
                         hunter.statVIT >= req &&
                         hunter.statWIS >= req

        if statsReady {
            hunter.rank = next
            hunter.gold += 50
            pendingRankUp = next
        }
    }

    // MARK: - Rank down check
    private func checkRankDown() {
        guard hunter.rank.rawValue > 0,
              let prev = HunterRank(rawValue: hunter.rank.rawValue - 1) else { return }
        let minStat = prev.statRequired
        if hunter.statSTR < minStat || hunter.statINT < minStat ||
           hunter.statVIT < minStat || hunter.statWIS < minStat {
            hunter.rank = prev
            hunter.gold = max(0, hunter.gold - 50)
        }
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
        }
    }

    private func reverseReward(reward: QuestDefinition.Reward) {
        switch reward.type {
        case .str:  hunter.statSTR = max(10, hunter.statSTR - reward.value)
        case .int:  hunter.statINT = max(10, hunter.statINT - reward.value)
        case .vit:  hunter.statVIT = max(10, hunter.statVIT - reward.value)
        case .wis:  hunter.statWIS = max(10, hunter.statWIS - reward.value)
        case .gold: hunter.gold = max(0, hunter.gold - reward.value)
        }
    }

    // App-open reconciliation. The streak is *earned* by completing quests
    // (registerActiveDay), never by opening the app — so here we only break a streak
    // whose missed-day gap can no longer be rescued by shields. Shields are spent on
    // return (in registerActiveDay), not here; lastActiveDate is never touched here.
    private func checkStreak() {
        guard hunter.streak > 0, let last = hunter.lastActiveDate else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let lastDay = cal.startOfDay(for: last)
        let missed = (cal.dateComponents([.day], from: lastDay, to: today).day ?? 0) - 1
        if missed > 0 && hunter.streakShields < missed {
            hunter.streak = 0
            save()
        }
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

// MARK: - Local notifications
// Morning reminder (repeating daily) + an evening "streak at risk" warning scheduled per-day
// for the next week, cancelled for any day once its quests are complete.
enum NotificationManager {
    static let morningId = "daily_reminder"
    private static let warningPrefix = "streak_warning_"
    static let reminderHour = 9
    static let warningHour = 20

    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleMorningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Quests Await"
        content.body = "Rise, Hunter. Your training begins."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: morningId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    /// (Re)schedule the evening warning for today + the next 6 days. Adding a request with an
    /// existing identifier replaces it, so this is safe to call repeatedly.
    static func scheduleStreakWarnings() {
        for offset in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: offset, to: .now) {
                scheduleWarning(for: day)
            }
        }
    }

    static func scheduleWarning(for date: Date) {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = warningHour
        comps.minute = 0
        guard let fire = cal.date(from: comps), fire > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your Streak Is At Risk"
        content.body = "Complete today's quests before midnight to keep your streak alive."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: warningId(for: date), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    static func cancelWarning(for date: Date) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [warningId(for: date)])
    }

    private static func warningId(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return warningPrefix + f.string(from: date)
    }
}
