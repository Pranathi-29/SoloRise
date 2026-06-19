import SwiftUI

struct DayDetailView: View {
    let log: DailyLog
    let date: Date
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date).uppercased()
    }

    private var quests: [(name: String, sfSymbol: String, color: Color, done: Bool)] {[
        ("Daily Training",        "figure.strengthtraining.traditional", Color.sysRed,    log.workoutDone),
        ("Nutrition (Protein+Fiber)", "fork.knife",                      Color.sysGreen,  log.nutritionDone),
        ("Skill Up",              "terminal.fill",                       Color.sysBlue,   log.studyDone),
        ("Lore & Learning",       "book.fill",                          Color.sysPurple, log.readingDone),
        ("Recovery Protocol",     "moon.stars.fill",                    Color(hex: "#5B8CFF"), log.recoveryDone),
    ]}

    private var completedCount: Int { quests.filter(\.done).count }

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.sysCard2)
                            .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(dateString)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysBlue)
                            .tracking(2)
                        Text("\(completedCount)/5 QUESTS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    // Balance the X button
                    Color.clear.frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.sysPanel)

                LinearGradient(
                    colors: [.clear, .sysBlue.opacity(0.5), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 1)

                ScrollView {
                    VStack(spacing: 10) {
                        // Completion summary ring
                        summaryCard

                        // Quest list
                        VStack(spacing: 0) {
                            ForEach(quests, id: \.name) { quest in
                                questRow(quest)
                                if quest.name != quests.last?.name {
                                    Rectangle()
                                        .fill(Color.sysBorder)
                                        .frame(height: 1)
                                }
                            }
                        }
                        .background(Color.sysCard2)
                        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))

                        // Buffs
                        if log.supplementsBuff || log.waterBuff || log.proteinBuff {
                            buffsCard
                        }
                    }
                    .padding(20)
                }
            }
        }
        .presentationBackground(Color.sysBG)
    }

    // MARK: - Summary card
    private var summaryCard: some View {
        HStack(spacing: 20) {
            // Mini ring
            ZStack {
                Circle()
                    .stroke(Color.sysBorder, lineWidth: 8)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: CGFloat(completedCount) / 5.0)
                    .stroke(
                        completedCount == 5 ? Color.sysGreen : Color.sysBlue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (completedCount == 5 ? Color.sysGreen : Color.sysBlue).opacity(0.5), radius: 6)
                VStack(spacing: 0) {
                    Text("\(completedCount)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("/5")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if completedCount == 5 {
                    Text("PERFECT DAY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysGreen)
                    Text("All quests completed")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                } else if completedCount == 0 {
                    Text("NO ACTIVITY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                    Text("No quests completed")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textDim)
                } else {
                    Text("\(completedCount) QUESTS DONE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysBlue)
                    Text("\(5 - completedCount) missed")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                // XP estimate
                let xp = [15, 12, 20, 12, 10]
                let earned = zip(quests, xp).filter(\.0.done).map(\.1).reduce(0, +)
                Text("+\(earned) EXP earned")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.sysPurple)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(completedCount == 5 ? Color.sysGreen : Color.sysBlue)
                .frame(width: 3)
        }
    }

    // MARK: - Quest row
    private func questRow(_ quest: (name: String, sfSymbol: String, color: Color, done: Bool)) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .fill(quest.done ? quest.color.opacity(0.1) : Color.sysBorder.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: quest.sfSymbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(quest.done ? quest.color : Color.textDim)
            }

            Text(quest.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(quest.done ? Color.textPrimary : Color.textDim)
                .strikethrough(!quest.done, color: Color.textDim.opacity(0.4))

            Spacer()

            Image(systemName: quest.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundStyle(quest.done ? quest.color : Color.textDim)
                .shadow(color: quest.done ? quest.color.opacity(0.5) : .clear, radius: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Buffs card
    private var buffsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PASSIVE BUFFS ACTIVE")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysGold)
                .tracking(2)

            if log.supplementsBuff {
                buffRow(icon: "pills.fill", name: "Supplements taken", color: .sysPurple)
            }
            if log.waterBuff {
                buffRow(icon: "drop.fill", name: "Water goal reached", color: .sysBlue)
            }
            if log.proteinBuff {
                buffRow(icon: "xmark.circle.fill", name: "No junk food", color: .sysRed)
            }
        }
        .padding(14)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysGoldDim, lineWidth: 1))
    }

    private func buffRow(icon: String, name: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(name)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
