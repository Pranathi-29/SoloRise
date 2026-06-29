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
        .background(Color.clear)
    }

    private var sysHeader: some View {
        let cleared = gates.filter(\.isCleared).count
        let summoned = shadows.filter(\.isSummoned).count
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("IRONVEIL DOMAIN")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("\(cleared) \(cleared == 1 ? "gate" : "gates") cleared · \(summoned) \(summoned == 1 ? "shadow" : "shadows") summoned")
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

            Image(systemName: gate.sfSymbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(gate.isOpen ? gate.rankColor : Color.textDim)
                .opacity(gate.isOpen ? 1 : 0.35)
                .shadow(color: gate.isOpen ? gate.rankColor.opacity(0.6) : .clear, radius: 6)

            Text(gate.name)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(gate.isOpen ? Color.textPrimary : Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if gate.isCleared {
                Text("CLEARED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
                    .tracking(1)
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7))
                    Text(gate.requirement)
                        .font(.system(size: 8, design: .monospaced))
                }
                .foregroundStyle(Color.textDim)
                .lineLimit(1)
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
            Image(systemName: shadow.sfSymbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(shadow.isSummoned ? Color.sysBlue : Color.textDim)
                .opacity(shadow.isSummoned ? 1 : 0.25)
                .shadow(color: shadow.isSummoned ? Color.sysBlue.opacity(0.9) : .clear, radius: 10)
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
    let sfSymbol: String
    let name: String
    let rankLabel: String
    let rankColor: Color
    let requirement: String
    let isCleared: Bool
    var isOpen: Bool { isCleared }

    static func all(for hunter: Hunter) -> [GateData] {
        let str = hunter.statSTR
        let int = hunter.statINT
        let vit = hunter.statVIT
        let wis = hunter.statWIS
        let power = hunter.power

        return [
            .init(id:"g1", sfSymbol:"checkmark.shield.fill", name:"Beginners Gate",  rankLabel:"RANK E", rankColor:.rankE, requirement:"Start",     isCleared:true),
            .init(id:"g2", sfSymbol:"leaf.fill",             name:"Forest Dungeon",  rankLabel:"RANK E", rankColor:.rankE, requirement:"VIT 25",    isCleared:vit>=25),
            .init(id:"g3", sfSymbol:"shield.fill",           name:"Iron Keep",       rankLabel:"RANK D", rankColor:.rankD, requirement:"STR 40",    isCleared:str>=40),
            .init(id:"g4", sfSymbol:"books.vertical.fill",   name:"Scholar Vault",   rankLabel:"RANK D", rankColor:.rankD, requirement:"INT 40",    isCleared:int>=40),
            .init(id:"g5", sfSymbol:"snowflake",             name:"Frost Citadel",   rankLabel:"RANK C", rankColor:.rankC, requirement:"WIS 65",    isCleared:wis>=65),
            .init(id:"g6", sfSymbol:"flame.fill",            name:"Inferno Rift",    rankLabel:"RANK B", rankColor:.rankB, requirement:"STR 95",    isCleared:str>=95),
            .init(id:"g7", sfSymbol:"moon.fill",             name:"Shadow Fortress", rankLabel:"RANK A", rankColor:.rankA, requirement:"WIS 130",   isCleared:wis>=130),
            .init(id:"g8", sfSymbol:"eye.fill",              name:"Monarchs Domain", rankLabel:"RANK S", rankColor:.rankS, requirement:"INT 130",   isCleared:int>=130),
            .init(id:"g9", sfSymbol:"crown.fill",            name:"Ashborn Throne",  rankLabel:"RANK S", rankColor:.rankS, requirement:"Power 520", isCleared:power>=520),
        ]
    }
}

struct ShadowData: Identifiable {
    let id: String
    let sfSymbol: String
    let name: String
    let isSummoned: Bool

    static func all(for hunter: Hunter) -> [ShadowData] {
        let str = hunter.statSTR
        let int = hunter.statINT
        let vit = hunter.statVIT
        let wis = hunter.statWIS
        let power = hunter.power
        return [
            .init(id:"s1", sfSymbol:"figure.fencing",          name:"IGRIS",     isSummoned: str >= 40),
            .init(id:"s2", sfSymbol:"ant.fill",                name:"BERU",      isSummoned: int >= 40),
            .init(id:"s3", sfSymbol:"shield.lefthalf.filled",  name:"TUSK",      isSummoned: wis >= 40),
            .init(id:"s4", sfSymbol:"lizard.fill",             name:"KAISEL",    isSummoned: vit >= 40),
            .init(id:"s5", sfSymbol:"flame.fill",              name:"IRON",      isSummoned: str >= 95),
            .init(id:"s6", sfSymbol:"pawprint.fill",           name:"TANK",      isSummoned: vit >= 95),
            .init(id:"s7", sfSymbol:"moon.stars.fill",         name:"GREED",     isSummoned: int >= 95),
            .init(id:"s8", sfSymbol:"eye.trianglebadge.exclamationmark", name:"ARCHITECT", isSummoned: power >= 520),
        ]
    }
}
