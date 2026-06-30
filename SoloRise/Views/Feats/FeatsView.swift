import SwiftUI

struct FeatsView: View {
    let store: HunterStore

    private var bosses: [BossData] { BossData.all(for: store.hunter) }
    private var milestones: [MilestoneData] {
        MilestoneData.all(for: store.hunter, hasPerfectDay: store.hasPerfectDay)
    }

    @State private var showInsights = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                raidsHeader
                insightsButton
                SysSection(title: "BOSS RAID LOG")
                ForEach(bosses) { boss in BossCard(boss: boss) }
                SysSection(title: "MILESTONES").padding(.top, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(78)), GridItem(.fixed(78))], spacing: 10) {
                        ForEach(milestones) { ms in MilestoneBadge(ms: ms) }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(14)
        }
        .background(Color.clear)
        .sheet(isPresented: $showInsights) { InsightsView(store: store) }
    }

    private var insightsButton: some View {
        Button { showInsights = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.sysBlue)
                Text("VIEW INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary).tracking(1.5)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundStyle(Color.textDim)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.sysCard2)
            .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var raidsHeader: some View {
        let slain = bosses.filter(\.isSlain).count
        let earned = milestones.filter(\.isEarned).count
        return HStack(spacing: 0) {
            headerStat(value: "\(slain)/\(bosses.count)", label: "BOSSES SLAIN")
            Rectangle().fill(Color.sysBorder).frame(width: 1)
            headerStat(value: "\(earned)/\(milestones.count)", label: "MILESTONES")
            Rectangle().fill(Color.sysBorder).frame(width: 1)
            headerStat(value: "\(store.hunter.streak)", label: "DAY STREAK")
        }
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func headerStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
    }
}

// MARK: - Boss Card
struct BossCard: View {
    let boss: BossData
    var pct: CGFloat { min(CGFloat(boss.current) / CGFloat(boss.threshold), 1.0) }

    var body: some View {
        VStack(spacing: 8) {                       // ← gap between rows
            HStack(spacing: 12) {
                // SF Symbol boss icon
                ZStack {
                    Rectangle()
                        .fill(boss.isSlain ? Color.sysGold.opacity(0.1) : boss.color.opacity(0.08))
                        .overlay(Rectangle().stroke(
                            boss.isSlain ? Color.sysGoldDim : boss.color.opacity(0.3), lineWidth: 1))
                    Image(systemName: boss.sfSymbol)
                        .font(.system(size: 20, weight: .medium))   // ← icon glyph size
                        .foregroundStyle(boss.isSlain ? Color.sysGold : boss.color)
                        .shadow(color: (boss.isSlain ? Color.sysGold : boss.color).opacity(0.6), radius: 8)
                }
                .frame(width: 44, height: 44)       // ← icon tile size

                VStack(alignment: .leading, spacing: 2) {
                    Text(boss.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(boss.isSlain ? Color.sysGold : Color.textPrimary)
                    Text(boss.description)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                if boss.isSlain {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.sysGold)
                        .font(.system(size: 18))
                        .shadow(color: Color.sysGold.opacity(0.5), radius: 6)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.sysBorder)
                    Rectangle()
                        .fill(boss.isSlain ? Color.sysGold : boss.color)
                        .frame(width: geo.size.width * pct)
                        .shadow(color: (boss.isSlain ? Color.sysGold : boss.color).opacity(0.5), radius: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text("\(boss.current) / \(boss.threshold)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                if boss.isSlain {
                    Text("⚔ SLAIN · \(boss.reward)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysGold).tracking(1)
                } else {
                    Text("REWARD: \(boss.reward)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.textDim)
                }
            }
        }
        .padding(11)                               // ← overall card padding
        .background(boss.isSlain ? Color.sysGold.opacity(0.04) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            boss.isSlain ? Color.sysGoldDim : Color.sysBorder, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(boss.isSlain ? Color.sysGold : boss.color)
                .frame(width: 3)
        }
    }
}

// MARK: - Milestone badge (horizontal trophy shelf)
struct MilestoneBadge: View {
    let ms: MilestoneData
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Rectangle()
                    .fill(ms.isEarned ? Color.sysGold.opacity(0.12) : Color.sysCard2)
                    .overlay(Rectangle().stroke(
                        ms.isEarned ? Color.sysGoldDim : Color.sysBorder, lineWidth: 1))
                Image(systemName: ms.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ms.isEarned ? Color.sysGold : Color.textDim)
                    .shadow(color: ms.isEarned ? Color.sysGold.opacity(0.5) : .clear, radius: 5)
                    .opacity(ms.isEarned ? 1 : 0.4)
                    .symbolEffect(.bounce, value: ms.isEarned)
            }
            .frame(width: 54, height: 54)

            Text(ms.label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(ms.isEarned ? Color.sysGold : Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 60)
        }
    }
}

// MARK: - Data

// Bosses are the major, stat/rank-driven endgame goals (distinct from the small
// early-win milestones). Slaying one pays out gold, awarded once via Hunter.bossClaimMask.
struct BossDefinition: Identifiable {
    enum Metric { case str, int, vit, wis, power }

    let id: String
    let sfSymbol: String
    let color: Color
    let name: String
    let description: String
    let threshold: Int
    let goldReward: Int
    let metric: Metric

    func current(for hunter: Hunter) -> Int {
        switch metric {
        case .str:   return hunter.statSTR
        case .int:   return hunter.statINT
        case .vit:   return hunter.statVIT
        case .wis:   return hunter.statWIS
        case .power: return hunter.power
        }
    }

    static let all: [BossDefinition] = [
        .init(id: "iron_troll", sfSymbol: "hammer.fill", color: .sysRed,
              name: "The Iron Troll",
              description: "Forge a body of iron — reach STR 190",
              threshold: 190, goldReward: 250, metric: .str),
        .init(id: "procrastination_dragon", sfSymbol: "lizard.fill", color: .sysBlue,
              name: "The Procrastination Dragon",
              description: "Conquer the grind — reach INT 190",
              threshold: 190, goldReward: 250, metric: .int),
        .init(id: "chaos_monarch", sfSymbol: "tornado", color: .sysPurple,
              name: "The Chaos Monarch",
              description: "Attain total balance — reach Power 1200",
              threshold: 1200, goldReward: 1000, metric: .power),
    ]
}

struct BossData: Identifiable {
    let id: String
    let sfSymbol: String
    let color: Color
    let name: String
    let description: String
    let current: Int
    let threshold: Int
    let reward: String
    let isSlain: Bool

    static func all(for hunter: Hunter) -> [BossData] {
        BossDefinition.all.enumerated().map { i, b in
            let claimed = (hunter.bossClaimMask & (1 << i)) != 0
            let raw = b.current(for: hunter)
            return BossData(
                id: b.id,
                sfSymbol: b.sfSymbol,
                color: b.color,
                name: b.name,
                description: b.description,
                current: min(raw, b.threshold),
                threshold: b.threshold,
                reward: "\(b.goldReward) Gold",
                isSlain: claimed || raw >= b.threshold
            )
        }
    }
}

struct MilestoneData: Identifiable {
    let id: String
    let label: String
    let icon: String
    let isEarned: Bool

    static func all(for hunter: Hunter, hasPerfectDay: Bool) -> [MilestoneData] {
        let total = hunter.totalWorkouts + hunter.totalStudySessions +
                    hunter.totalHealthyDays + hunter.totalReadingSessions +
                    hunter.totalRecoveryDays
        let r = hunter.rank.rawValue
        let s = hunter.streak
        return [
            // Getting started
            .init(id:"m1",  label:"First Quest",  icon:"flag.checkered",          isEarned: total >= 1),
            .init(id:"m2",  label:"Perfect Day",  icon:"star.fill",               isEarned: hasPerfectDay),
            // Quest volume
            .init(id:"m3",  label:"10 Quests",    icon:"checklist",               isEarned: total >= 10),
            .init(id:"m4",  label:"50 Quests",    icon:"checklist",               isEarned: total >= 50),
            .init(id:"m5",  label:"200 Quests",   icon:"checklist",               isEarned: total >= 200),
            // Streaks
            .init(id:"m6",  label:"3-Day",        icon:"flame",                   isEarned: s >= 3),
            .init(id:"m7",  label:"7-Day",        icon:"flame.fill",              isEarned: s >= 7),
            .init(id:"m8",  label:"14-Day",       icon:"flame.circle",            isEarned: s >= 14),
            .init(id:"m9",  label:"30-Day",       icon:"flame.circle.fill",       isEarned: s >= 30),
            .init(id:"m10", label:"100-Day",      icon:"flame.circle.fill",       isEarned: s >= 100),
            // Ranks
            .init(id:"m11", label:"D-Rank",       icon:"arrow.up.circle",         isEarned: r >= 1),
            .init(id:"m12", label:"C-Rank",       icon:"arrow.up.circle.fill",    isEarned: r >= 2),
            .init(id:"m13", label:"B-Rank",       icon:"chevron.up.circle.fill",  isEarned: r >= 3),
            .init(id:"m14", label:"A-Rank",       icon:"chevron.up.2",            isEarned: r >= 4),
            .init(id:"m15", label:"S-Rank",       icon:"crown.fill",              isEarned: r >= 5),
            // Systems
            .init(id:"m16", label:"First Gate",   icon:"door.left.hand.open",     isEarned: hunter.statVIT >= 25),
            .init(id:"m17", label:"3 Shields",    icon:"shield.lefthalf.filled",  isEarned: hunter.streakShields >= 3),
            .init(id:"m18", label:"Power 300",    icon:"bolt.fill",               isEarned: hunter.power >= 300),
        ]
    }
}

// MARK: - Insights
struct InsightsView: View {
    let store: HunterStore
    @Environment(\.dismiss) private var dismiss
    @State private var coachingLoading = false
    @State private var coachingError: String? = nil

    private var reasonTally: [(reason: String, count: Int)] {
        Dictionary(grouping: store.hunter.missLog, by: { $0.reason })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { (reason: $0.key, count: $0.value) }
    }

    private var recentMisses: [MissReason] {
        store.hunter.missLog.sorted { $0.date > $1.date }.prefix(8).map { $0 }
    }

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                ScrollView {
                    VStack(spacing: 14) {
                        coachingSection
                        overallCard
                        byQuestSection
                        reasonsSection
                    }
                    .padding(16)
                }
            }
        }
        .presentationBackground(Color.sysBG)
    }

    private var header: some View {
        HStack {
            Text("INSIGHTS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysBlue).tracking(3)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.sysCard2)
                    .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(Color.sysPanel)
    }

    private var coachingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("WEEKLY COACHING")
            VStack(alignment: .leading, spacing: 10) {
                if !store.hunter.coachingSummary.isEmpty {
                    Text(store.hunter.coachingSummary)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let d = store.hunter.coachingDate {
                        Text("Generated \(d.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textDim)
                    }
                }
                if let err = coachingError {
                    Text(err)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.sysRed)
                }
                if store.hasAPIKey {
                    Button { Task { await runCoaching() } } label: {
                        HStack(spacing: 8) {
                            if coachingLoading {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "sparkles").font(.system(size: 12))
                            }
                            Text(store.hunter.coachingSummary.isEmpty
                                 ? "GET THIS WEEK'S COACHING" : "REFRESH COACHING")
                                .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(coachingLoading ? Color.sysBorder2 : Color.sysBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(coachingLoading)
                } else {
                    Text("Add your Gemini key in Settings → AI Coach to enable coaching.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(12)
            .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
        .id(store.refreshTick)
    }

    @MainActor
    private func runCoaching() async {
        coachingError = nil
        coachingLoading = true
        do {
            try await store.requestWeeklyCoaching()
        } catch {
            coachingError = error.localizedDescription
        }
        coachingLoading = false
    }

    private var overallCard: some View {
        HStack(spacing: 0) {
            statCell("\(store.hunter.streak)", "CURRENT")
            divider
            statCell("\(store.hunter.maxStreak)", "LONGEST")
            divider
            statCell("\(store.totalQuestsDone)", "QUESTS")
            divider
            statCell("\(store.hunter.gold)", "GOLD")
        }
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
    }

    private var divider: some View { Rectangle().fill(Color.sysBorder).frame(width: 1) }
    private var rowDivider: some View { Rectangle().fill(Color.sysBorder).frame(height: 1) }

    private var byQuestSection: some View {
        VStack(spacing: 0) {
            sectionHeader("BY QUEST")
            VStack(spacing: 0) {
                ForEach(Array(QuestDefinition.all.enumerated()), id: \.element.id) { i, def in
                    questRow(def)
                    if i < QuestDefinition.all.count - 1 { rowDivider }
                }
            }
            .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func questRow(_ def: QuestDefinition) -> some View {
        let overdue = store.missedDays(def.questID) >= HunterStore.missNudgeThreshold
        return HStack(spacing: 12) {
            Image(systemName: def.sfSymbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(def.questID.color)
                .frame(width: 28)
            Text(def.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(store.timesDone(def.questID))×")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(store.lastDoneDescription(def.questID))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(overdue ? Color.sysGold : Color.textSecondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
    }

    private var reasonsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("WHY I MISSED")
            VStack(spacing: 0) {
                if store.hunter.missLog.isEmpty {
                    Text("Nothing logged yet. If you skip a quest for 3 days, you can note why — and it shows up here.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                } else {
                    if let top = reasonTally.first {
                        HStack {
                            Text("Most common")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(top.reason) · \(top.count)×")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.sysGold)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        rowDivider
                    }
                    ForEach(recentMisses) { entry in
                        reasonRow(entry)
                        if entry.id != recentMisses.last?.id { rowDivider }
                    }
                }
            }
            .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private func reasonRow(_ entry: MissReason) -> some View {
        let questName = QuestDefinition.all.first { $0.questID.rawValue == entry.questRaw }?.name ?? entry.questRaw
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(questName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(entry.reason)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysGold)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysBlue).tracking(2)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Color.sysPanel)
    }
}
