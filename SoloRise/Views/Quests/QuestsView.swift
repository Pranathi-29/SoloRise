import SwiftUI

struct QuestsView: View {
    let store: HunterStore
    @State private var showReward: QuestDefinition? = nil

    private let buffs: [(label: String, effect: String, sfSymbol: String, color: Color, keyPath: WritableKeyPath<DailyLog, Bool>)] = [
        ("Supplements taken", "+5% VIT EXP", "pills.fill",      .sysPurple, \.supplementsBuff),
        ("Water goal reached", "+8% VIT EXP", "drop.fill",      .sysBlue,   \.waterBuff),
        ("No junk food",       "+6% STR EXP", "xmark.circle.fill", .sysRed,  \.proteinBuff),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                progressBar
                SysSection(title: "DAILY QUESTS")
                ForEach(QuestDefinition.all) { quest in
                    QuestRow(
                        quest: quest,
                        isDone: store.isComplete(quest.questID),
                        onComplete: {
                            store.completeQuest(quest.questID)
                            showReward = quest
                        },
                        onUncomplete: {
                            store.uncompleteQuest(quest.questID)
                            Haptic.tap()
                        }
                    )
                }
                SysSection(title: "PASSIVE BUFFS").padding(.top, 4)
                ForEach(buffs, id: \.label) { buff in
                    BuffRow(
                        sfSymbol: buff.sfSymbol,
                        color: buff.color,
                        name: buff.label,
                        effect: buff.effect,
                        isOn: store.todayLog[keyPath: buff.keyPath]
                    ) {
                        store.toggleBuff(buff.keyPath)
                        Haptic.tap()
                    }
                }
            }
            .padding(14)
        }
        .background(Color.clear)
        .sheet(item: $showReward) { q in
            QuestClearSheet(quest: q) { showReward = nil }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 12) {
            Text("DAILY PROGRESS")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(2)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.sysBorder)
                    Rectangle().fill(Color.sysGreen)
                        .frame(width: geo.size.width * progressFraction)
                        .animation(.easeOut(duration: 0.5), value: store.questProgress.done)
                }
            }
            .frame(height: 4)
            Text("\(store.questProgress.done)/\(store.questProgress.total)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysGreen)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }

    private var progressFraction: CGFloat {
        let p = store.questProgress
        guard p.total > 0 else { return 0 }
        return CGFloat(p.done) / CGFloat(p.total)
    }
}

// MARK: - Quest Row
struct QuestRow: View {
    let quest: QuestDefinition
    let isDone: Bool
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            ZStack {
                Rectangle()
                    .stroke(isDone ? Color.sysGreen : Color.sysBorder2, lineWidth: 1)
                    .frame(width: 22, height: 22)
                if isDone {
                    Rectangle().fill(Color.sysGreen).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                }
            }

            // SF Symbol icon
            ZStack {
                Rectangle()
                    .fill(questColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: quest.sfSymbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isDone ? Color.textSecondary : questColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(quest.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDone ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(isDone, color: .white.opacity(0.2))
                HStack(spacing: 6) {
                    ForEach(quest.rewards, id: \.label) { reward in
                        RewardPill(label: reward.label, color: pillColor(reward))
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(isDone ? Color.sysGreen.opacity(0.04) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            isDone ? Color.sysGreen.opacity(0.3) : Color.sysBorder, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isDone ? Color.sysGreen : questColor)
                .frame(width: 3)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isDone { onUncomplete() } else { onComplete() }
        }
        .animation(.easeOut(duration: 0.2), value: isDone)
    }

    private var questColor: Color {
        switch quest.questID {
        case .workout:   return .sysRed
        case .nutrition: return .sysGreen
        case .study:     return .sysBlue
        case .reading:   return .sysPurple
        case .recovery:  return Color(hex: "#5B8CFF")
        }
    }

    private func pillColor(_ reward: QuestDefinition.Reward) -> Color {
        switch reward.type {
        case .str: return .sysRed;   case .int: return .sysBlue
        case .vit: return .sysGreen; case .wis: return .sysPurple
        case .xp:  return .sysBlue;  case .gold: return .sysGold
        }
    }
}

// MARK: - Buff Row
struct BuffRow: View {
    let sfSymbol: String
    let color: Color
    let name: String
    let effect: String
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: sfSymbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isOn ? color : Color.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isOn ? color : Color.textPrimary)
                Text(effect)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(isOn ? color.opacity(0.7) : Color.textSecondary)
            }
            Spacer()
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? color.opacity(0.3) : Color.sysBorder2)
                    .frame(width: 40, height: 24)
                Circle().fill(isOn ? color : Color.textDim)
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 2)
            }
            .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(isOn ? color.opacity(0.05) : Color.sysCard2)
        .overlay(Rectangle().stroke(isOn ? color.opacity(0.3) : Color.sysBorder, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
