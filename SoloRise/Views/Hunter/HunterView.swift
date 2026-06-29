import SwiftUI

struct HunterView: View {
    let store: HunterStore
    @State private var showEditName = false
    @State private var showRewards = false
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let cardH = geo.size.height * 0.36

            ScrollView {
                VStack(spacing: 8) {
                    statusWindow
                    characterCard(imageHeight: cardH)
                    statSection
                    bottomRow
                    activityRing
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .sheet(isPresented: $showEditName) {
            EditNameView(name: Binding(
                get: { store.hunter.name },
                set: { store.hunter.name = $0; try? store.modelContext.save() }
            ))
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showRewards) {
            RewardsView(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
    }

    // MARK: - Character card with dynamic image height
    private func characterCard(imageHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("HUNTER PROFILE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.sysBlue)
                Spacer()
                Text(store.hunter.rank.title.uppercased())
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(store.hunter.rank.color)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.sysPanel)

            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, store.hunter.rank.color.opacity(0.7), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            // Image
            ZStack(alignment: .bottom) {
                Image(rankImageName(store.hunter.rank))
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipped()

                // Bottom fade
                LinearGradient(
                    colors: [.clear, Color.sysCard.opacity(0.95)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 70)

                // Rank label overlay
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.hunter.rank.label + " RANK")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(store.hunter.rank.color)
                            .shadow(color: store.hunter.rank.color.opacity(0.9), radius: 8)
                        Text(rankSubtitle(store.hunter.rank))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                            .tracking(2)
                    }
                    Spacer()
                    if let next = store.hunter.rank.next {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NEXT: \(next.label) RANK")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(Color.textDim)
                        }
                    } else {
                        Text("MAX RANK")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(store.hunter.rank.color)
                            .shadow(color: store.hunter.rank.color, radius: 6)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .background(Color.sysCard)
        }
        .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
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
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.leading, 10)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.sysPanel)

            LinearGradient(colors: [.clear, .sysBlue.opacity(0.6), .clear],
                           startPoint: .leading, endPoint: .trailing).frame(height: 1)

            HStack(alignment: .center, spacing: 14) {
                // Rank badge
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(store.hunter.rank.color.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 2)
                            .stroke(store.hunter.rank.color, lineWidth: 2))
                        .shadow(color: store.hunter.rank.color.opacity(0.6), radius: 10)
                    Text(store.hunter.rank.label)
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(store.hunter.rank.color)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(store.hunter.name)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textDim)
                    }
                    .onTapGesture { showEditName = true }

                    HStack(spacing: 8) {
                        Text("PWR")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.sysBorder)
                                Rectangle().fill(store.hunter.rank.color)
                                    .frame(width: geo.size.width * CGFloat(store.hunter.rankProgress))
                                    .overlay(alignment: .trailing) {
                                        Rectangle().fill(store.hunter.rank.color.opacity(0.9)).frame(width: 3)
                                    }
                                    .animation(.easeOut(duration: 0.6), value: store.hunter.power)
                            }
                        }
                        .frame(height: 4)
                        Text("\(store.hunter.power)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color.sysCard)
        }
        .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
    }

    // MARK: - Stats & Promotion (merged)
    private var statSection: some View {
        let req = store.hunter.rank.statRequired
        let strOK = store.hunter.statSTR >= req
        let intOK = store.hunter.statINT >= req
        let vitOK = store.hunter.statVIT >= req
        let wisOK = store.hunter.statWIS >= req
        let allOK = strOK && intOK && vitOK && wisOK

        return VStack(spacing: 0) {
            HStack {
                Text("STATS & PROMOTION")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(allOK ? Color.sysGold : Color.sysBlue)
                Spacer()
                if let next = store.hunter.rank.next {
                    Text("→ \(next.label) RANK")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(store.hunter.rank.next?.color ?? Color.textDim)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.sysPanel)

            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, (allOK ? Color.sysGold : Color.sysBlue).opacity(0.5), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            HStack(spacing: 0) {
                statCell(label: "STR", value: store.hunter.statSTR, req: req, color: .sysRed, met: strOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statCell(label: "INT", value: store.hunter.statINT, req: req, color: .sysBlue, met: intOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statCell(label: "VIT", value: store.hunter.statVIT, req: req, color: .sysGreen, met: vitOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statCell(label: "WIS", value: store.hunter.statWIS, req: req, color: .sysPurple, met: wisOK)
            }
            .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(allOK ? Color.sysGold.opacity(0.6) : Color.sysBorder, lineWidth: 1))
        .id(store.refreshTick)
    }

    private func statCell(label: String, value: Int, req: Int, color: Color, met: Bool) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(met ? .white : Color.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.sysBorder)
                    Rectangle()
                        .fill(color.opacity(met ? 1.0 : 0.7))
                        .frame(width: geo.size.width * min(CGFloat(value) / CGFloat(req), 1.0))
                }
            }
            .frame(height: 2)
            .padding(.horizontal, 4)
            HStack(spacing: 2) {
                Image(systemName: met ? "checkmark" : "arrow.up")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(met ? Color.sysBlue : Color.textDim)
                Text(met ? "READY" : "/\(req)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(met ? Color.sysBlue : Color.textDim)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Gold + Streak
    private var bottomRow: some View {
        HStack(spacing: 8) {
            bottomStat(icon: "dollarsign.circle.fill", label: "GOLD",
                       value: "\(store.hunter.gold)", color: .sysGold, iconColor: .sysGold)
                .onTapGesture { showRewards = true }
            bottomStat(icon: "flame.fill", label: "STREAK",
                       value: "\(store.hunter.streak)D", color: .orange, iconColor: .orange,
                       pulse: store.hunter.streak > 0)
            bottomStat(icon: "shield.fill", label: "SHIELDS",
                       value: "\(store.hunter.streakShields)", color: .sysBlue, iconColor: .sysBlue)
        }
        .id(store.refreshTick)
    }

    private func bottomStat(icon: String, label: String, value: String,
                             color: Color, iconColor: Color, pulse: Bool = false) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 13))
                .symbolEffect(.pulse, options: .repeating, isActive: pulse)
            Text(label).font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity Ring
    private var activityRing: some View {
        let p = store.questProgress
        let fraction = p.total > 0 ? Double(p.done) / Double(p.total) : 0
        return ActivityRing(progress: fraction, done: p.done, total: p.total)
            .id(p.done)
    }

    // MARK: - Helpers
    private func rankImageName(_ rank: HunterRank) -> String {
        switch rank {
        case .e: return "rank_e"
        case .d: return "rank_d"
        case .c: return "rank_c"
        case .b: return "rank_b"
        case .a: return "rank_a"
        case .s: return "rank_s"
        }
    }

    private func rankSubtitle(_ rank: HunterRank) -> String {
        switch rank {
        case .e: return "SHADOW FRAGMENT"
        case .d: return "SHADOW SCOUT"
        case .c: return "SHADOW ROGUE"
        case .b: return "SHADOW KNIGHT"
        case .a: return "SHADOW COMMANDER"
        case .s: return "ECLIPSE GENERAL"
        }
    }
}

// MARK: - Reward Vault (real-life rewards bought with gold, gated by rank)
struct RewardsView: View {
    let store: HunterStore
    @Environment(\.dismiss) private var dismiss
    @State private var titles: [Int: String] = [:]

    private func rankLabel(_ raw: Int) -> String { ["E","D","C","B","A","S"][raw] }
    private func rankColor(_ raw: Int) -> Color { (HunterRank(rawValue: raw) ?? .e).color }

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                ScrollView {
                    VStack(spacing: 10) {
                        goldBanner
                        ForEach(store.hunter.rankRewards) { reward in
                            rewardRow(reward)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .presentationBackground(Color.sysBG)
        .onAppear {
            for r in store.hunter.rankRewards { titles[r.rankRaw] = r.title }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("REWARD VAULT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue).tracking(3)
                Text("Spend gold on real-life rewards")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
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

    private var goldBanner: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(Color.sysGold).font(.system(size: 18))
            Text("AVAILABLE GOLD")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1.5)
            Spacer()
            Text("\(store.hunter.gold)")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(Color.sysGold)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysGoldDim, lineWidth: 1))
        .id(store.refreshTick)
    }

    private func titleBinding(_ reward: RankReward) -> Binding<String> {
        Binding(
            get: { titles[reward.rankRaw] ?? reward.title },
            set: { newVal in
                titles[reward.rankRaw] = newVal
                store.setRewardTitle(rankRaw: reward.rankRaw, title: newVal)
            }
        )
    }

    private func rewardRow(_ reward: RankReward) -> some View {
        let unlocked = store.isUnlocked(reward)
        let claimable = store.canClaim(reward)
        let rc = rankColor(reward.rankRaw)
        return HStack(spacing: 12) {
            ZStack {
                Rectangle().fill(rc.opacity(0.1))
                    .overlay(Rectangle().stroke(rc, lineWidth: 1))
                Text(rankLabel(reward.rankRaw))
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(rc)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                TextField("", text: titleBinding(reward),
                          prompt: Text("Set a reward…").foregroundColor(.textDim))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(reward.claimed ? Color.textSecondary : .white)
                    .disabled(reward.claimed)
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 9)).foregroundStyle(Color.sysGold)
                    Text("\(reward.goldCost) GOLD")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            statusView(reward, unlocked: unlocked, claimable: claimable)
        }
        .padding(14)
        .background(reward.claimed ? Color.sysGold.opacity(0.05) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            reward.claimed ? Color.sysGoldDim : (unlocked ? rc.opacity(0.4) : Color.sysBorder),
            lineWidth: 1))
        .opacity(unlocked || reward.claimed ? 1 : 0.6)
    }

    @ViewBuilder
    private func statusView(_ reward: RankReward, unlocked: Bool, claimable: Bool) -> some View {
        if reward.claimed {
            VStack(spacing: 3) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18)).foregroundStyle(Color.sysGold)
                    .symbolEffect(.bounce, value: reward.claimed)
                Text("CLAIMED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysGold)
            }
        } else if claimable {
            Button {
                store.claimReward(reward); Haptic.rankUp()
            } label: {
                Text("CLAIM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.sysGold)
            }
            .buttonStyle(.plain)
        } else if !unlocked {
            VStack(spacing: 3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12)).foregroundStyle(Color.textDim)
                Text("RANK \(rankLabel(reward.rankRaw))")
                    .font(.system(size: 8, design: .monospaced)).foregroundStyle(Color.textDim)
            }
        } else {
            Text(reward.title.isEmpty ? "SET REWARD" : "NEED \(reward.goldCost)g")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color.textDim)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
        }
    }
}
