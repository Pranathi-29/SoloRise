import SwiftUI

struct HunterView: View {
    let store: HunterStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                statusWindow
                statsGrid
                bottomRow
                activityRing
                questSummaryToday
            }
            .padding(14)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Status Window
    private var statusWindow: some View {
        VStack(spacing: 0) {
            HStack {
                Text("HUNTER STATUS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2).foregroundStyle(Color.sysBlue)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.sysGreen).frame(width: 6, height: 6)
                    Text("ACTIVE")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.sysGreen)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.sysPanel)

            LinearGradient(colors: [.clear, .sysBlue.opacity(0.6), .clear],
                           startPoint: .leading, endPoint: .trailing).frame(height: 1)

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(store.hunter.rank.color.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 2)
                            .stroke(store.hunter.rank.color, lineWidth: 2))
                        .shadow(color: store.hunter.rank.color.opacity(0.6), radius: 10)
                    Text(store.hunter.rank.label)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(store.hunter.rank.color)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.hunter.name)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(store.hunter.rank.title.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.sysPurple).tracking(1)

                    HStack(spacing: 8) {
                        Text("EXP")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.sysBorder)
                                Rectangle().fill(Color.sysBlue)
                                    .frame(width: geo.size.width * xpFraction)
                                    .overlay(alignment: .trailing) {
                                        Rectangle().fill(Color.sysCyan.opacity(0.9)).frame(width: 3)
                                    }
                                    .animation(.easeOut(duration: 0.6), value: store.hunter.xp)
                            }
                        }
                        .frame(height: 6)
                        Text("\(store.hunter.xp)/\(store.hunter.rank.xpRequired)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color.sysCard)
        }
        .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                StatBar(label: "STR", value: store.hunter.statSTR, color: .sysRed)
                StatBar(label: "INT", value: store.hunter.statINT, color: .sysBlue)
            }
            HStack(spacing: 6) {
                StatBar(label: "VIT", value: store.hunter.statVIT, color: .sysGreen)
                StatBar(label: "WIS", value: store.hunter.statWIS, color: .sysPurple)
            }
        }
    }

    // MARK: - Gold + Streak
    private var bottomRow: some View {
        HStack(spacing: 8) {
            bottomStat(icon: "dollarsign.circle.fill", label: "GOLD",
                       value: "\(store.hunter.gold)", color: .sysGold, iconColor: .sysGold)
            bottomStat(icon: "flame.fill", label: "STREAK",
                       value: "\(store.hunter.streak) DAYS", color: .orange, iconColor: .orange)
        }
    }

    private func bottomStat(icon: String, label: String, value: String,
                             color: Color, iconColor: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 14))
            Text(label).font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1)
            Spacer()
            Text(value).font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity Ring
    private var activityRing: some View {
        let p = store.questProgress
        let fraction = p.total > 0 ? Double(p.done) / Double(p.total) : 0
        return ActivityRing(
            progress: fraction,
            done: p.done,
            total: p.total
        )
        .id(p.done) // redraw when quests complete
    }

    // MARK: - Quest summary
    private var questSummaryToday: some View {
        let done = store.questProgress.done
        let total = store.questProgress.total
        let allDone = done == total

        return HStack(spacing: 12) {
            Image(systemName: allDone ? "checkmark.seal.fill" : "clock")
                .foregroundStyle(allDone ? Color.sysGreen : Color.textSecondary)
                .font(.system(size: 16))
            Text(allDone ? "ALL QUESTS CLEARED TODAY" : "\(total - done) QUESTS REMAINING")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(allDone ? Color.sysGreen : Color.textSecondary)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(allDone ? Color.sysGreen.opacity(0.06) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            allDone ? Color.sysGreen.opacity(0.4) : Color.sysBorder, lineWidth: 1))
    }

    private var xpFraction: CGFloat {
        let max = store.hunter.rank.xpRequired
        guard max > 0 else { return 0 }
        return min(CGFloat(store.hunter.xp) / CGFloat(max), 1)
    }
}
