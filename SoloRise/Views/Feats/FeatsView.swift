import SwiftUI

struct FeatsView: View {
    let store: HunterStore

    private var bosses: [BossData] { BossData.all(for: store.hunter) }
    private var milestones: [MilestoneData] {
        MilestoneData.all(for: store.hunter, hasPerfectDay: store.hasPerfectDay)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                raidsHeader
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
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // SF Symbol boss icon
                ZStack {
                    Rectangle()
                        .fill(boss.isSlain ? Color.sysGold.opacity(0.1) : boss.color.opacity(0.08))
                        .overlay(Rectangle().stroke(
                            boss.isSlain ? Color.sysGoldDim : boss.color.opacity(0.3), lineWidth: 1))
                    Image(systemName: boss.sfSymbol)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(boss.isSlain ? Color.sysGold : boss.color)
                        .shadow(color: (boss.isSlain ? Color.sysGold : boss.color).opacity(0.6), radius: 8)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(boss.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(boss.isSlain ? Color.sysGold : Color.textPrimary)
                    Text(boss.description)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                if boss.isSlain {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.sysGold)
                        .font(.system(size: 22))
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
            .frame(height: 5)

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
        .padding(14)
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
