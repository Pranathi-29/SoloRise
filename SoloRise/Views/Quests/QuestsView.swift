import SwiftUI

struct QuestsView: View {
    let store: HunterStore
    @State private var showReward: QuestDefinition? = nil
    @State private var claimCounts: [QuestID: Int] = [:]
    @State private var nudgeQuest: QuestID? = nil

    private let buffs: [(label: String, sfSymbol: String, color: Color, keyPath: WritableKeyPath<DailyLog, Bool>)] = [
        ("Hydration",    "drop.fill",  .sysGreen,  \.waterBuff),
        ("Supplements",  "pills.fill", .sysPurple, \.supplementsBuff),
        ("Clean Eating", "leaf.fill",  .sysRed,    \.proteinBuff),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let nudge = store.currentNudge {
                    nudgeBanner(nudge)
                        .transition(.opacity)
                        .id(store.refreshTick)
                }
                if allCleared {
                    allClearBanner
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else {
                    progressBar
                        .transition(.opacity)
                }
                SysSection(title: "DAILY QUESTS")
                ForEach(QuestDefinition.all) { quest in
                    QuestRow(
                        quest: quest,
                        isDone: store.isComplete(quest.questID),
                        claimCount: claimCounts[quest.questID] ?? 0,
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
                SysSection(title: "BONUS QUESTS").padding(.top, 4)
                shieldStatus
                HStack(spacing: 8) {
                    ForEach(buffs, id: \.label) { buff in
                        BuffBadge(
                            sfSymbol: buff.sfSymbol,
                            color: buff.color,
                            name: buff.label,
                            isOn: store.todayLog[keyPath: buff.keyPath]
                        ) {
                            store.toggleBuff(buff.keyPath)
                            Haptic.tap()
                        }
                    }
                }
            }
            .padding(14)
            .animation(.easeOut(duration: 0.35), value: allCleared)
        }
        .background(Color.clear)
        .sheet(item: $showReward) { q in
            QuestClearSheet(quest: q) {
                showReward = nil
                claimCounts[q.questID, default: 0] += 1
            }
        }
        .sheet(item: $nudgeQuest) { q in
            if let def = QuestDefinition.all.first(where: { $0.questID == q }) {
                MissReasonSheet(quest: def) { reason, note in
                    store.logMissReason(q, reason: reason, note: note)
                }
            }
        }
    }

    // MARK: - Miss nudge banner
    private func nudgeBanner(_ id: QuestID) -> some View {
        let def = QuestDefinition.all.first { $0.questID == id }
        let days = store.missedDays(id)
        return HStack(spacing: 12) {
            ZStack {
                Rectangle().fill(Color.sysGold.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: def?.sfSymbol ?? "questionmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.sysGold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(def?.name ?? "A quest") · \(days) days")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("Tap to note what's getting in the way")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Button { store.dismissNudge(id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textDim)
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.sysGold.opacity(0.06))
        .overlay(Rectangle().stroke(Color.sysGoldDim, lineWidth: 1))
        .overlay(alignment: .leading) { Rectangle().fill(Color.sysGold).frame(width: 3) }
        .contentShape(Rectangle())
        .onTapGesture { nudgeQuest = id }
    }

    private var allCleared: Bool {
        store.questProgress.done == store.questProgress.total
    }

    private var allBonusToday: Bool {
        store.todayLog.waterBuff && store.todayLog.supplementsBuff && store.todayLog.proteinBuff
    }

    // MARK: - Streak shield status
    private var shieldStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 16))
                .foregroundStyle(Color.sysBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("STREAK SHIELDS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue).tracking(1.5)
                Text(allBonusToday ? "Banked today — streak protected"
                                   : "Complete all 3 to bank one")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<HunterStore.maxShields, id: \.self) { i in
                    Image(systemName: i < store.hunter.streakShields ? "shield.fill" : "shield")
                        .font(.system(size: 13))
                        .foregroundStyle(i < store.hunter.streakShields ? Color.sysBlue : Color.sysBorder2)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
        .id(store.refreshTick)
    }

    // MARK: - All-clear banner
    private var allClearBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .fill(Color.sysBlue.opacity(0.12))
                    .overlay(Rectangle().stroke(Color.sysBlue.opacity(0.5), lineWidth: 1))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.sysBlue)
                    .shadow(color: Color.sysBlue.opacity(0.6), radius: 8)
                    .symbolEffect(.bounce, value: allCleared)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("ALL QUESTS CLEARED")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
                    .tracking(1.5)
                Text("Daily objectives complete. Rest, Hunter.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text("\(store.questProgress.done)/\(store.questProgress.total)")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(Color.sysBlue)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.sysBlue.opacity(0.06))
        .overlay(Rectangle().stroke(Color.sysBlue.opacity(0.4), lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.sysBlue).frame(width: 3)
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
                    Rectangle().fill(Color.sysBlue)
                        .frame(width: geo.size.width * progressFraction)
                        .animation(.easeOut(duration: 0.5), value: store.questProgress.done)
                }
            }
            .frame(height: 4)
            Text("\(store.questProgress.done)/\(store.questProgress.total)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysBlue)
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
    let claimCount: Int
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            ZStack {
                Rectangle()
                    .stroke(isDone ? Color.sysBlue : Color.sysBorder2, lineWidth: 1)
                    .frame(width: 22, height: 22)
                if isDone {
                    Rectangle().fill(Color.sysBlue).frame(width: 22, height: 22)
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
                    .symbolEffect(.bounce, value: claimCount)
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
        .background(isDone ? Color.sysBlue.opacity(0.04) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            isDone ? Color.sysBlue.opacity(0.3) : Color.sysBorder, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isDone ? Color.sysBlue : questColor)
                .frame(width: 3)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isDone { onUncomplete() } else { onComplete() }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isDone)
    }

    private var questColor: Color { quest.questID.color }

    private func pillColor(_ reward: QuestDefinition.Reward) -> Color { reward.type.color }
}

// MARK: - Buff Badge
struct BuffBadge: View {
    let sfSymbol: String
    let color: Color
    let name: String
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 7) {                       // ← gap between icon / name / status
            ZStack {
                Rectangle()
                    .fill(isOn ? color.opacity(0.15) : Color.sysBorder.opacity(0.15))
                    .frame(width: 38, height: 38)  // ← icon tile size
                Image(systemName: sfSymbol)
                    .font(.system(size: 17, weight: .medium))   // ← icon glyph size
                    .foregroundStyle(isOn ? color : Color.textDim)
                    .shadow(color: isOn ? color.opacity(0.6) : .clear, radius: 6)
            }

            Text(name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? Color.textPrimary : Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(isOn ? "DONE" : "—")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(isOn ? color : Color.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)                    // ← overall tile height
        .background(isOn ? color.opacity(0.06) : Color.sysCard2)
        .overlay(Rectangle().stroke(isOn ? color.opacity(0.4) : Color.sysBorder, lineWidth: 1))
        .overlay(alignment: .top) {
            if isOn {
                Rectangle().fill(color).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .animation(.easeOut(duration: 0.2), value: isOn)
    }
}

// MARK: - "Why did I miss" reason sheet
struct MissReasonSheet: View {
    let quest: QuestDefinition
    let onLog: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: MissReasonOption? = nil
    @State private var note: String = ""

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: quest.sfSymbol)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(quest.questID.color)
                    Text("WHAT'S GETTING IN THE WAY?")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysBlue).tracking(2)
                        .multilineTextAlignment(.center)
                    Text("You haven't done \(quest.name) in a few days. No judgment — noting it helps you spot the pattern.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 24)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(MissReasonOption.allCases) { opt in
                        let isSel = selected == opt
                        Button { selected = opt } label: {
                            Text(opt.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSel ? .black : Color.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isSel ? Color.sysBlue : Color.sysCard2)
                                .overlay(Rectangle().stroke(
                                    isSel ? Color.sysBlue : Color.sysBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("", text: $note,
                          prompt: Text("Add a note (optional)").foregroundColor(.textDim))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 12)
                    .background(Color.sysCard2)
                    .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))

                Spacer()

                Button {
                    onLog(selected?.rawValue ?? "Other", note)
                    dismiss()
                } label: {
                    Text("LOG IT")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(3).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(selected == nil ? Color.sysBorder2 : Color.sysBlue)
                }
                .buttonStyle(.plain)
                .disabled(selected == nil)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.sysBG)
    }
}
