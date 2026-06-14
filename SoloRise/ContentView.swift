import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: HunterStore?
    @State private var selectedTab: Tab = .hunter

    enum Tab { case hunter, quests, gates, feats }

    var body: some View {
        Group {
            if let store {
                mainView(store: store)
            } else {
                bootScreen
            }
        }
        .onAppear {
            store = HunterStore(modelContext: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store?.onAppActive()
            }
        }
    }

    // MARK: - Main
    private func mainView(store: HunterStore) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color.sysBG.ignoresSafeArea()
                switch selectedTab {
                case .hunter: HunterView(store: store)
                case .quests: QuestsView(store: store)
                case .gates:  GatesView(store: store)
                case .feats:  FeatsView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SystemTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            if let newRank = store.pendingRankUp {
                RankUpOverlay(rank: newRank) {
                    store.pendingRankUp = nil
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.pendingRankUp != nil)
    }

    // MARK: - Boot screen
    private var bootScreen: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("SYSTEM")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
                    .tracking(8)
                Text("INITIALIZING...")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(4)
            }
        }
    }
}

// MARK: - Tab Bar
struct SystemTabBar: View {
    @Binding var selected: ContentView.Tab

    private let tabs: [(tab: ContentView.Tab, icon: String, label: String)] = [
        (.hunter, "shield.lefthalf.filled", "HUNTER"),
        (.quests, "scroll",                 "QUESTS"),
        (.gates,  "door.left.hand.open",    "GATES"),
        (.feats,  "medal",                  "FEATS"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .sysBlue.opacity(0.6), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(tabs, id: \.label) { item in
                    tabButton(item)
                }
            }
            .background(Color.sysPanel)
            .padding(.bottom, 28)
        }
        .background(Color.sysPanel)
    }

    private func tabButton(_ item: (tab: ContentView.Tab, icon: String, label: String)) -> some View {
        let isSelected = selected == item.tab
        return Button {
            Haptic.tap()
            selected = item.tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.sysBlue : Color.textSecondary)
                Text(item.label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(isSelected ? Color.sysBlue : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.sysBlue.opacity(0.07) : Color.clear)
            .overlay(alignment: .top) {
                if isSelected {
                    Rectangle().fill(Color.sysBlue).frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Rank Up Overlay
struct RankUpOverlay: View {
    let rank: HunterRank
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text("[ SYSTEM MESSAGE ]")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.sysGold).tracking(3)

                Text(rank.label)
                    .font(.system(size: 72, weight: .black, design: .monospaced))
                    .foregroundStyle(rank.color)
                    .shadow(color: rank.color.opacity(0.8), radius: 20)

                Text("YOU HAVE BEEN PROMOTED")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textSecondary).tracking(3)

                Text(rank.title.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rank.color).tracking(2)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("+1")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysBlue)
                        Text("STAT POINT")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text("+50")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysGold)
                        Text("GOLD")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Button {
                    Haptic.rankUp()
                    onDismiss()
                } label: {
                    Text("ACKNOWLEDGE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(3).foregroundStyle(Color.sysGold)
                        .padding(.horizontal, 32).padding(.vertical, 12)
                        .overlay(Rectangle().stroke(Color.sysGold, lineWidth: 1))
                }
            }
            .padding(32)
            .background(Color.sysPanel)
            .overlay(Rectangle().stroke(Color.sysGoldDim, lineWidth: 1))
            .overlay(alignment: .top) {
                LinearGradient(colors: [.clear, .sysGold, .clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .sysGold, .clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
            }
            .padding(.horizontal, 32)
        }
    }
}
