import SwiftUI

struct HunterView: View {
    let store: HunterStore
    @State private var showEditName = false

    var body: some View {
        GeometryReader { geo in
            let cardH = geo.size.height * 0.38

            ScrollView {
                VStack(spacing: 10) {
                    statusWindow
                    characterCard(imageHeight: cardH)
                    promotionRequirements
                    statsGrid
                    bottomRow
                    activityRing
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
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

    // MARK: - Promotion Requirements
    private var promotionRequirements: some View {
        let req = store.hunter.rank.statRequired
        let strOK = store.hunter.statSTR >= req
        let intOK = store.hunter.statINT >= req
        let vitOK = store.hunter.statVIT >= req
        let wisOK = store.hunter.statWIS >= req
        let allOK = strOK && intOK && vitOK && wisOK

        return VStack(spacing: 0) {
            HStack {
                Text("PROMOTION REQUIREMENTS")
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
                .fill(LinearGradient(colors: [.clear, (allOK ? Color.sysGold : Color.sysBlue).opacity(0.5), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            HStack(spacing: 0) {
                statReqCell(label: "STR", value: store.hunter.statSTR, req: req, color: .sysRed, met: strOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statReqCell(label: "INT", value: store.hunter.statINT, req: req, color: .sysBlue, met: intOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statReqCell(label: "VIT", value: store.hunter.statVIT, req: req, color: .sysGreen, met: vitOK)
                Rectangle().fill(Color.sysBorder).frame(width: 1)
                statReqCell(label: "WIS", value: store.hunter.statWIS, req: req, color: .sysPurple, met: wisOK)
            }
            .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(allOK ? Color.sysGold.opacity(0.6) : Color.sysBorder, lineWidth: 1))
        .id(store.refreshTick)
    }

    private func statReqCell(label: String, value: Int, req: Int, color: Color, met: Bool) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(met ? .white : Color.textSecondary)
            HStack(spacing: 2) {
                Image(systemName: met ? "checkmark" : "arrow.up")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(met ? Color.sysGreen : Color.textDim)
                Text(met ? "READY" : "/\(req)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(met ? Color.sysGreen : Color.textDim)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        .id(store.refreshTick)
    }

    // MARK: - Gold + Streak
    private var bottomRow: some View {
        HStack(spacing: 8) {
            bottomStat(icon: "dollarsign.circle.fill", label: "GOLD",
                       value: "\(store.hunter.gold)", color: .sysGold, iconColor: .sysGold)
            bottomStat(icon: "flame.fill", label: "STREAK",
                       value: "\(store.hunter.streak)D", color: .orange, iconColor: .orange)
        }
        .id(store.refreshTick)
    }

    private func bottomStat(icon: String, label: String, value: String,
                             color: Color, iconColor: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 13))
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
