import SwiftUI

struct GatesView: View {
    let store: HunterStore

    private var gates: [GateData] { GateData.all(for: store.hunter) }
    private var shadows: [ShadowData] { ShadowData.all(for: store.hunter) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                sysHeader

                SysSection(title: "GATE REGISTRY")

                // Gate grid 3-col
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(gates) { gate in
                        GateCard(gate: gate)
                    }
                }

                SysSection(title: "SHADOW ARMY")
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(shadows) { shadow in
                        ShadowCard(shadow: shadow)
                    }
                }
            }
            .padding(14)
        }
        .background(Color.sysBG)
    }

    private var sysHeader: some View {
        let cleared = gates.filter(\.isCleared).count
        let summoned = shadows.filter(\.isSummoned).count
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("IRONVEIL DOMAIN")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("\(cleared) gates cleared · \(summoned) shadows summoned")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("RANK")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                Text(store.hunter.rank.label)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(store.hunter.rank.color)
            }
        }
        .padding(14)
        .background(Color.sysCard2)
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }
}

// MARK: - Gate Card
struct GateCard: View {
    let gate: GateData

    var body: some View {
        VStack(spacing: 6) {
            Text(gate.rankLabel)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(gate.isOpen ? gate.rankColor : Color.textDim)

            Text(gate.icon).font(.system(size: 26))
                .opacity(gate.isOpen ? 1 : 0.3)

            Text(gate.name)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(gate.isOpen ? Color.textPrimary : Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if gate.isCleared {
                Text("CLEARED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysGreen)
                    .tracking(1)
            } else if gate.isOpen {
                Text("ENTERED")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
            } else {
                Text(gate.requirement)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.textDim)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(gate.isOpen ? gate.rankColor.opacity(0.05) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            gate.isOpen ? gate.rankColor.opacity(0.35) : Color.sysBorder, lineWidth: 1))
        .opacity(gate.isOpen ? 1 : 0.45)
    }
}

// MARK: - Shadow Card
struct ShadowCard: View {
    let shadow: ShadowData

    var body: some View {
        VStack(spacing: 5) {
            Text(shadow.icon).font(.system(size: 22))
                .opacity(shadow.isSummoned ? 1 : 0.25)
                .shadow(color: shadow.isSummoned ? Color.sysPurple.opacity(0.8) : .clear, radius: 8)
            Text(shadow.name)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(shadow.isSummoned ? Color.sysPurple : Color.textDim)
                .tracking(0.5)
        }
        .padding(.vertical, 10).padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(shadow.isSummoned ? Color.sysPurple.opacity(0.06) : Color.sysCard2)
        .overlay(Rectangle().stroke(
            shadow.isSummoned ? Color.sysPurpleDim : Color.sysBorder, lineWidth: 1))
    }
}

// MARK: - Data models
struct GateData: Identifiable {
    let id: String
    let icon: String
    let name: String
    let rankLabel: String
    let rankColor: Color
    let requirement: String
    let isOpen: Bool
    let isCleared: Bool

    static func all(for hunter: Hunter) -> [GateData] {
        let w = hunter.totalWorkouts
        let s = hunter.totalStudySessions
        let r = hunter.rank.rawValue

        return [
            .init(id:"g1", icon:"🚪", name:"Beginners Gate",   rankLabel:"RANK E", rankColor:.rankE, requirement:"Start", isOpen:true,       isCleared:true),
            .init(id:"g2", icon:"🌲", name:"Forest Dungeon",   rankLabel:"RANK E", rankColor:.rankE, requirement:"3 workouts",  isOpen:w>=3,   isCleared:w>=3),
            .init(id:"g3", icon:"🗡️", name:"Iron Keep",        rankLabel:"RANK D", rankColor:.rankD, requirement:"10 workouts", isOpen:w>=10,  isCleared:false),
            .init(id:"g4", icon:"📖", name:"Scholar Vault",    rankLabel:"RANK D", rankColor:.rankD, requirement:"25 study",    isOpen:s>=25,  isCleared:false),
            .init(id:"g5", icon:"🏔️", name:"Frost Citadel",    rankLabel:"RANK C", rankColor:.rankC, requirement:"C-Rank",      isOpen:r>=2,   isCleared:false),
            .init(id:"g6", icon:"🌋", name:"Inferno Rift",     rankLabel:"RANK B", rankColor:.rankB, requirement:"B-Rank",      isOpen:r>=3,   isCleared:false),
            .init(id:"g7", icon:"🏰", name:"Shadow Fortress",  rankLabel:"RANK A", rankColor:.rankA, requirement:"A-Rank",      isOpen:r>=4,   isCleared:false),
            .init(id:"g8", icon:"👁️", name:"Monarchs Domain",  rankLabel:"RANK S", rankColor:.rankS, requirement:"S-Rank",      isOpen:r>=5,   isCleared:false),
            .init(id:"g9", icon:"⚔️", name:"Ashborn Throne",   rankLabel:"RANK S", rankColor:.rankS, requirement:"All 30 days", isOpen:false,  isCleared:false),
        ]
    }
}

struct ShadowData: Identifiable {
    let id: String
    let icon: String
    let name: String
    let isSummoned: Bool

    static func all(for hunter: Hunter) -> [ShadowData] {
        let w = hunter.totalWorkouts
        let s = hunter.totalStudySessions
        let r = hunter.rank.rawValue
        return [
            .init(id:"s1", icon:"💀", name:"IGRIS",     isSummoned: w >= 5),
            .init(id:"s2", icon:"🐺", name:"BERU",      isSummoned: s >= 10),
            .init(id:"s3", icon:"🗡️", name:"TUSK",      isSummoned: w >= 15),
            .init(id:"s4", icon:"🐍", name:"KAISEL",    isSummoned: r >= 2),
            .init(id:"s5", icon:"🔥", name:"IRON",      isSummoned: w >= 30),
            .init(id:"s6", icon:"⚡", name:"TANK",      isSummoned: s >= 25),
            .init(id:"s7", icon:"🌑", name:"GREED",     isSummoned: r >= 3),
            .init(id:"s8", icon:"👁️", name:"ARCHITECT", isSummoned: r >= 5),
        ]
    }
}
