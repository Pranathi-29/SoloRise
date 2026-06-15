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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(milestones) { ms in MilestoneItem(ms: ms) }
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

// MARK: - Milestone
struct MilestoneItem: View {
    let ms: MilestoneData
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: ms.isEarned ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(ms.isEarned ? Color.sysGreen : Color.textDim)
            Text(ms.label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(ms.isEarned ? Color.sysGreen : Color.textSecondary)
                .lineLimit(2).minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .background(ms.isEarned ? Color.sysGreen.opacity(0.05) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            ms.isEarned ? Color.sysGreen.opacity(0.3) : Color.sysBorder, lineWidth: 1))
    }
}

// MARK: - Data
struct BossData: Identifiable {
    let id: String
    let sfSymbol: String
    let color: Color
    let name: String
    let description: String
    let current: Int
    let threshold: Int
    let reward: String
    var isSlain: Bool { current >= threshold }

    static func all(for hunter: Hunter) -> [BossData] {
        [
            .init(id: "b1",
                  sfSymbol: "flame.fill",
                  color: .sysRed,
                  name: "The Procrastination Dragon",
                  description: "Complete 30 study sessions",
                  current: hunter.totalStudySessions,
                  threshold: 30,
                  reward: "Scholar Vault"),
            .init(id: "b2",
                  sfSymbol: "figure.strengthtraining.traditional",
                  color: .sysBlue,
                  name: "The Iron Troll",
                  description: "Complete 20 workouts",
                  current: hunter.totalWorkouts,
                  threshold: 20,
                  reward: "Iron Keep"),
            .init(id: "b3",
                  sfSymbol: "wind",
                  color: .sysPurple,
                  name: "The Chaos Monarch",
                  description: "Maintain a 14-day streak",
                  current: hunter.streak,
                  threshold: 14,
                  reward: "Stability Bonus"),
        ]
    }
}

struct MilestoneData: Identifiable {
    let id: String
    let label: String
    let isEarned: Bool

    static func all(for hunter: Hunter, hasPerfectDay: Bool) -> [MilestoneData] {
        let total = hunter.totalWorkouts + hunter.totalStudySessions +
                    hunter.totalHealthyDays + hunter.totalReadingSessions +
                    hunter.totalRecoveryDays
        return [
            .init(id:"m1",  label:"First quest complete",  isEarned: total >= 1),
            .init(id:"m2",  label:"3-day streak",          isEarned: hunter.streak >= 3),
            .init(id:"m3",  label:"Reached D-Rank",        isEarned: hunter.rank.rawValue >= 1),
            .init(id:"m4",  label:"100 gold earned",       isEarned: hunter.gold >= 100),
            .init(id:"m5",  label:"5-day streak",          isEarned: hunter.streak >= 5),
            .init(id:"m6",  label:"All quests in one day", isEarned: hasPerfectDay),
            .init(id:"m7",  label:"10 study sessions",     isEarned: hunter.totalStudySessions >= 10),
            .init(id:"m8",  label:"20 workouts",           isEarned: hunter.totalWorkouts >= 20),
            .init(id:"m9",  label:"Reached C-Rank",        isEarned: hunter.rank.rawValue >= 2),
            .init(id:"m10", label:"30-day streak",         isEarned: hunter.streak >= 30),
        ]
    }
}
