import SwiftUI

struct QuestClearSheet: View, Identifiable {
    let quest: QuestDefinition
    let onDismiss: () -> Void
    var id: String { quest.questID.rawValue }

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("[ QUEST COMPLETE ]")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue).tracking(3)

                // Large SF Symbol
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(questColor.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(questColor.opacity(0.4), lineWidth: 1))
                    Image(systemName: quest.sfSymbol)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(questColor)
                        .shadow(color: questColor.opacity(0.6), radius: 12)
                }
                .frame(width: 100, height: 100)

                Text(quest.name.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white).tracking(2)
                    .multilineTextAlignment(.center)

                Text(quest.flavor)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.textSecondary).italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    ForEach(quest.rewards, id: \.label) { reward in
                        RewardPill(label: reward.label, color: pillColor(reward))
                    }
                }

                Spacer()

                Button { onDismiss() } label: {
                    Text("CLAIM REWARD")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(3).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(questColor)
                }
                .padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .presentationDetents([.fraction(0.6)])
        .presentationBackground(Color.sysBG)
        .onAppear { Haptic.questComplete() }
    }

    private var questColor: Color { quest.questID.color }

    private func pillColor(_ reward: QuestDefinition.Reward) -> Color { reward.type.color }
}
