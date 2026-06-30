import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: HunterStore?
    @State private var selectedTab: Tab = .hunter
    @State private var showLaunch: Bool = true
    @State private var onboarded: Bool = true

    enum Tab { case hunter, quests, gates, feats }

    var body: some View {
        ZStack {
            Group {
                if let store {
                    if onboarded {
                        mainView(store: store)
                    } else {
                        OnboardingView(store: store) { onboarded = true }
                    }
                } else {
                    Color(hex: "#07050F").ignoresSafeArea()
                }
            }
            if showLaunch {
                LaunchScreenView {
                    showLaunch = false
                }
                .transition(.opacity)
                .zIndex(99)
            }
        }
        .animation(.easeOut(duration: 0.3), value: showLaunch)
        .animation(.easeOut(duration: 0.3), value: onboarded)
        .onAppear {
            let s = HunterStore(modelContext: modelContext)
            store = s
            onboarded = s.hunter.hasOnboarded
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
                ParticleBackground()
                switch selectedTab {
                case .hunter: HunterView(store: store)
                case .quests: QuestsView(store: store)
                case .gates:  GatesView(store: store)
                case .feats:  FeatsView(store: store)
                }
            }
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SystemTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            if let newRank = store.pendingRankUp {
                RankUpOverlay(rank: newRank,
                              rewardTitle: store.reward(forRank: newRank)?.title) {
                    store.pendingRankUp = nil
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.pendingRankUp != nil)
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

struct RankUpOverlay: View {
    let rank: HunterRank
    var rewardTitle: String? = nil
    let onDismiss: () -> Void

    @State private var textVisible = false
    @State private var imageVisible = false
 
    var body: some View {
        ZStack {
            Color.black.opacity(0.97).ignoresSafeArea()
 
            VStack(spacing: 0) {
 
                // Character image — appears first
                if imageVisible {
                    RankUpCharacterView(rank: rank)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
 
                // Text — slides up after
                if textVisible {
                    VStack(spacing: 14) {
                        Text("[ SYSTEM MESSAGE ]")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.sysGold).tracking(3)
 
                        Text("YOU HAVE BEEN PROMOTED")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.textSecondary).tracking(2)
 
                        Text(rank.title.uppercased())
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(rank.color).tracking(2)
                            .shadow(color: rank.color.opacity(0.8), radius: 8)
 
                        VStack(spacing: 4) {
                            Text("+50")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.sysGold)
                            Text("GOLD")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(Color.textSecondary)
                        }

                        // Real-life reward unlocked at this rank
                        if let title = rewardTitle, !title.isEmpty {
                            VStack(spacing: 6) {
                                Text("REWARD UNLOCKED")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.sysGold).tracking(2)
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.sysGold)
                                        .symbolEffect(.bounce, value: textVisible)
                                    Text(title)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .overlay(Rectangle().stroke(Color.sysGoldDim, lineWidth: 1))
                        }

                        Button {
                            Haptic.rankUp()
                            onDismiss()
                        } label: {
                            Text("ACKNOWLEDGE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(3).foregroundStyle(rank.color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .overlay(Rectangle().stroke(rank.color, lineWidth: 1))
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 12)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                imageVisible = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
                textVisible = true
            }
            Haptic.rankUp()
        }
    }
}

// MARK: - Onboarding (first launch: name + real-life rewards)
struct OnboardingView: View {
    let store: HunterStore
    let onDone: () -> Void

    @State private var name: String = ""
    @State private var rewards: [String] = ["", "", "", "", ""]

    // index → rank that unlocks the reward (D, C, B, A, S) + its gold cost
    private let rankInfo: [(label: String, cost: Int, placeholder: String)] = [
        ("D", 400,  "e.g. New running shoes"),
        ("C", 800,  "e.g. Steak dinner out"),
        ("B", 1600, "e.g. That video game"),
        ("A", 3000, "e.g. Weekend getaway"),
        ("S", 5000, "e.g. Big-ticket reward"),
    ]

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("[ SYSTEM AWAKENING ]")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.sysGold).tracking(3)
                        Text("WELCOME, HUNTER")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.sysBlue).tracking(2)
                        Text("Forge your daily discipline and rise from E to S over the year ahead.")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 36)

                    fieldCard(label: "HUNTER NAME") {
                        TextField("", text: $name,
                                  prompt: Text("Enter your name").foregroundColor(.textDim))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.words)
                    }

                    VStack(spacing: 4) {
                        Text("SET YOUR REWARDS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysBlue).tracking(2)
                        Text("Name a real reward for each rank. Reach it, spend your saved gold, treat yourself.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 6)

                    ForEach(rankInfo.indices, id: \.self) { i in
                        fieldCard(label: "\(rankInfo[i].label)-RANK · \(rankInfo[i].cost) GOLD") {
                            TextField("", text: $rewards[i],
                                      prompt: Text(rankInfo[i].placeholder).foregroundColor(.textDim))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        store.completeOnboarding(name: name, rewardTitles: rewards)
                        Haptic.rankUp()
                        onDone()
                    } label: {
                        Text("BEGIN")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(4).foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.sysBlue)
                    }
                    .padding(.top, 8).padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func fieldCard<Content: View>(label: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textSecondary).tracking(1.5)
            content()
                .padding(.horizontal, 12).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.sysCard2)
                .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    let store: HunterStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("warningHour") private var warningHour = 20

    @State private var showRewards = false
    @State private var showEditName = false
    @State private var apiKeyInput = ""

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                ScrollView {
                    VStack(spacing: 14) {
                        notificationsSection
                        aiCoachSection
                        rewardsSection
                        aboutSection
                    }
                    .padding(16)
                }
            }
        }
        .presentationBackground(Color.sysBG)
        .sheet(isPresented: $showRewards) { RewardsView(store: store) }
        .sheet(isPresented: $showEditName) {
            EditNameView(name: Binding(
                get: { store.hunter.name },
                set: { store.hunter.name = $0; try? store.modelContext.save() }
            ))
            .presentationDetents([.medium])
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Text("SYSTEM SETTINGS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.sysBlue).tracking(3)
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

    // MARK: Notifications
    private var notificationsSection: some View {
        settingsCard("NOTIFICATIONS") {
            Toggle(isOn: $notificationsEnabled) {
                Text("Daily Reminders")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(.sysBlue)
            .onChange(of: notificationsEnabled) { _, on in
                if on { NotificationManager.requestAuthorization() }
                store.refreshNotifications()
            }
            .padding(.horizontal, 12).padding(.vertical, 10)

            if notificationsEnabled {
                rowDivider
                hourStepper(label: "Morning reminder", hour: $reminderHour)
                rowDivider
                hourStepper(label: "Streak warning", hour: $warningHour)
            }
        }
    }

    private func hourStepper(label: String, hour: Binding<Int>) -> some View {
        Stepper(value: hour, in: 0...23) {
            HStack {
                Text(label)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(formatHour(hour.wrappedValue))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue)
            }
        }
        .tint(.sysBlue)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .onChange(of: hour.wrappedValue) { _, _ in store.refreshNotifications() }
    }

    private func formatHour(_ h: Int) -> String {
        let period = h < 12 ? "AM" : "PM"
        var hr = h % 12
        if hr == 0 { hr = 12 }
        return "\(hr):00 \(period)"
    }

    // MARK: AI Coach
    private var aiCoachSection: some View {
        settingsCard("AI COACH") {
            if store.hasAPIKey {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14)).foregroundStyle(Color.sysGreen)
                    Text("Gemini key saved")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button("Remove") { store.clearAPIKey() }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysRed)
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste your free Gemini API key to enable weekly coaching.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                    SecureField("", text: $apiKeyInput,
                                prompt: Text("Gemini API key").foregroundColor(.textDim))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 10)
                        .background(Color.sysBG)
                        .overlay(Rectangle().stroke(Color.sysBorder2, lineWidth: 1))
                    Button {
                        store.saveAPIKey(apiKeyInput)
                        apiKeyInput = ""
                    } label: {
                        Text("SAVE KEY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.sysBorder2 : Color.sysBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(12)
            }
        }
    }

    // MARK: Rewards
    private var rewardsSection: some View {
        settingsCard("REWARDS & PROFILE") {
            settingsButton("Edit Rewards", icon: "gift.fill") { showRewards = true }
            rowDivider
            settingsButton("Edit Hunter Name", icon: "pencil") { showEditName = true }
        }
    }

    // MARK: About
    private var aboutSection: some View {
        settingsCard("ABOUT") {
            HStack {
                Text("SoloRise")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("v\(appVersion)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            rowDivider
            Text("Rise from Shadow Fragment to Eclipse General.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
        }
    }

    // MARK: Building blocks
    private var rowDivider: some View {
        Rectangle().fill(Color.sysBorder).frame(height: 1)
    }

    private func settingsButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.sysBlue)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textDim)
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsCard<C: View>(_ title: String,
                                       @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.sysBlue).tracking(2)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.sysPanel)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, .sysBlue.opacity(0.4), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)

            VStack(spacing: 0) { content() }
                .background(Color.sysCard2)
        }
        .overlay(Rectangle().stroke(Color.sysBorder, lineWidth: 1))
    }
}

