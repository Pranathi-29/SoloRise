# SoloRise — Project Summary

> A Solo Leveling-inspired iOS habit tracker built with SwiftUI + SwiftData.  
> Complete daily quests → grow your stats → rank up from Shadow Fragment to Eclipse General.

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Target | iOS 17.6+ |
| Language | Swift 5.0 |
| Architecture | `@Observable` ViewModel (`HunterStore`) |

---

## App Structure

```
SoloRise/
├── Models/
│   ├── Hunter.swift          # Player model — stats, rank, gold, streak, streakShields
│   ├── DailyLog.swift        # Per-day quest completion flags + bonus quests + shieldEarned
│   └── QuestDefinition.swift # Quest metadata, rewards, quest/reward colors
├── ViewModels/
│   └── HunterStore.swift     # All game logic — quests, rank-up, streak/shields, bosses, rewards
├── Views/
│   ├── Hunter/
│   │   ├── HunterView.swift         # Main Hunter tab (+ RewardsView reward vault)
│   │   ├── HunterCharacterView.swift # Character card + rank images
│   │   ├── ActivityRingView.swift    # Quest ring + month calendar sheet
│   │   ├── DayDetailView.swift       # Per-day quest log (tapped from calendar)
│   │   ├── EditNameView.swift        # Hunter name editor
│   │   └── MagicCircleView.swift     # (legacy — can be deleted)
│   ├── Quests/
│   │   └── QuestsView.swift          # Daily quest list + all-clear banner + bonus quests/shields
│   ├── Gates/
│   │   └── GatesView.swift           # ⚠️ UNUSED (gates removed) — safe to delete from project
│   ├── Feats/
│   │   └── FeatsView.swift           # Bosses + milestone trophy shelf + JournalView (reflection/insights/coaching)
│   ├── Overlays/
│   │   └── QuestClearSheet.swift     # Quest completion sheet
│   ├── Components/
│   │   ├── ParticleBackground.swift
│   │   ├── RankBadge.swift
│   │   ├── RewardPill.swift
│   │   ├── StatBar.swift
│   │   ├── SysSection.swift
│   │   └── SystemWindow.swift
│   └── LaunchScreenView.swift
└── Utilities/
    ├── SystemTheme.swift     # Color palette, haptics
    └── DateHelpers.swift
```

---

## Tabs

| Tab | What it does |
|-----|-------------|
| **Hunter** | Character profile, stats, power bar, promotion requirements, activity ring, rewards (gold tile), settings (gear) |
| **Quests** | Daily quest checklist + all-clear banner + bonus quests (streak shields) + miss nudge |
| **Journal** | Daily reflection (went well / got in the way) + weekly AI coaching + insights (stats, by-quest, why-I-missed) |
| **Feats** | Boss raids and milestone trophy shelf |

---

## Core Game Loop

```
Complete quest → Stat increases → Power bar fills
→ All 4 stats hit rank threshold → Rank up → New character art unlocks
```

### Quests → Stats mapping
| Quest | Stat | Per completion |
|-------|------|----------------|
| Physical Training (exercise) | STR | +1 |
| Nutrition | VIT | +1 |
| Career Growth (job prep) | INT | +1 |
| Mind Training (reading/learning) | WIS | +1 |
| Recovery (sleep/rest) | VIT | +1 |

Each quest also grants Gold (4–8). Stats start at 10. Quests give **+1 to their stat**
per completion, so a stat is effectively a count of reps done (e.g. STR 250 ≈ 250 training
sessions). VIT is fed by two quests (Nutrition + Recovery) so it advances fastest and is
rarely the rank bottleneck; STR / INT / WIS each have a single quest and set the real pace
(Career Growth / INT tends to be the true bottleneck).

### Rank Progression (stat-driven, XP removed)
Tuned so E→S takes **~1 year at ~80% consistency** (5–6 days/week), with an escalating curve.

| Rank | Title | Each stat must reach | ~Time at 80% |
|------|-------|----------------------|--------------|
| E | Shadow Fragment | — (starting rank, stats start at 10) | — |
| E → D | Shadow Scout | 25 each | ~3 wk |
| D → C | Shadow Rogue | 55 each | ~5 wk |
| C → B | Shadow Knight | 110 each | ~10 wk |
| B → A | Shadow Commander | 190 each | ~14 wk |
| A → S | Eclipse General | 300 each | ~20 wk |

Rank up triggers automatically when **all 4 stats** meet the threshold (enforces balanced
habits). The **power bar tracks the limiting (slowest) stat**, so it fills exactly in step
with the all-4 gate. `power` (STR+INT+VIT+WIS) is still shown as a flavor number.

### Streak & Bonus Quests → Streak Shields (Quests tab)
The streak is **earned by completing quests**, not by opening the app: the first quest
completed each day advances it (`registerActiveDay`); the very first quest sets it to 1.
App-open (`checkStreak`) only *breaks* a streak whose missed-day gap can't be rescued.

Bonus quests no longer affect stats. Completing **all 3 in a day banks 1 Streak Shield**
(max 3). When you return after missing day(s), a Shield is spent (1 per missed day) to bridge
the gap and **continue** the streak; a gap bigger than your shields restarts it at 1.

| Bonus quest | Tracks |
|-------------|--------|
| Hydration | Hit your water goal |
| Supplements | Took B12 / Mg |
| Clean Eating | No junk that day |

### Journal (Journal tab) — replaced the old Gates tab
`JournalView` (defined in `FeatsView.swift`) holds three stacked sections:
- **Daily Reflection** — two short fields, "what went well" / "what got in the way"
  (`HunterStore.saveReflection(wentWell:gotInWay:)`). No reward attached. Feeds the coach as
  dated, labeled lines **alongside** the logged miss-reasons so it can correlate the two.
- **Weekly Coaching** — Gemini summary + suggestions (see Real-Life Rewards / AI section).
- **Insights** — current/longest streak, total quests, gold; per-quest times-done + last-done;
  "why I missed" tally + recent log.

> **Gates were removed** (the milestone trophy shelf already covers stat-threshold collecting;
> gates were redundant). `GatesView.swift` / `GateData` / `GateCard` are now unused dead code —
> safe to delete from the Xcode project. `Hunter.gateClaimMask` is vestigial.

### Feats (Feats tab)
Two tiers, defined in `FeatsView.swift`:
- **Bosses** = major stat/rank endgame goals (`BossDefinition`), **pay gold once** when first
  slain (tracked by `Hunter.bossClaimMask`, awarded in `HunterStore.checkBosses()`):
  Iron Troll → STR 190 (250g, `hammer.fill`) · Procrastination Dragon → INT 190 (250g,
  `lizard.fill`) · Chaos Monarch → Power 1200 (1000g, `tornado`).
- **Milestones** = a horizontally-scrolling **trophy shelf** (`MilestoneBadge`, 2-row `LazyHGrid`):
  18 icon badges, gold + bounce when earned, dim when locked. Grouped: getting-started → quest
  volume (10/50/200) → streaks (3/7/14/30/100-day) → ranks (D→S) → systems (VIT 25, 3
  shields, Power 300). Append to `MilestoneData.all` to add more — the shelf scrolls to fit.

### Real-Life Rewards + Onboarding
The gold sink: the user pre-commits to **5 real-life rewards**, one per rank-up (D/C/B/A/S), a
*temptation-bundling* commitment device. Reach the rank, spend the gold you've saved, claim the
real reward.
- **Onboarding** (`OnboardingView` in `ContentView.swift`, gated by `Hunter.hasOnboarded`) —
  first launch sets the hunter name + the 5 reward titles.
- **Reward Vault** (`RewardsView` in `HunterView.swift`, opened by tapping the **Gold tile**) —
  view/edit reward titles, see Locked / CLAIM / CLAIMED state, claim to spend gold.
- Gold costs auto-assigned per rank (400 / 800 / 1600 / 3000 / 5000) — tuned to always be
  affordable right when the rank unlocks.
- Rewards stored as JSON-encoded `[RankReward]` on `Hunter.rankRewardsData` (no new `@Model`).
  Claim/onboarding logic in `HunterStore` (`completeOnboarding`, `claimReward`, `canClaim`,
  `setRewardTitle`). The rank-up overlay shows "REWARD UNLOCKED: …".

---

## Character System

- 6 rank-specific AI-generated portrait images (`rank_e.png` → `rank_s.png`)
- Stored in `Assets.xcassets`
- Image size: portrait, dark background that bleeds into app theme (`#07050F`)
- Card height: 38% of screen height, `scaledToFill`
- Rank-up overlay shows new rank's portrait with fade-in + reward text

### Rank art style
| Rank | Character |
|------|-----------|
| E — Shadow Fragment | Small dark shadow wisp, glowing purple eyes |
| D — Shadow Scout | (pending image) |
| C — Shadow Rogue | (pending image) |
| B — Shadow Knight | (pending image) |
| A — Shadow Commander | (pending image) |
| S — Eclipse General | (pending image) |

---

## Calendar / Activity Log

- Accessible by tapping the activity ring on the Hunter tab
- Real month-based calendar with `◀ ▶` navigation
- Each day cell shows 5 colored quest dots (filled = completed)
- Tap any past day → `DayDetailView` shows full quest breakdown for that day
- Stats row shows active days, perfect days, total quests for the viewed month
- Today highlighted with cyan border

---

## What's Working ✅

- [x] Full quest loop — complete, uncomplete, rewards apply/reverse
- [x] Stat-driven rank-up system (XP removed), +1/stat per quest
- [x] Rank thresholds tuned for ~1 year E→S at 80% consistency
- [x] Rank-down if stats drop below threshold (on uncomplete)
- [x] Merged Stats & Promotion section on Hunter tab (compact, per-stat progress + ✓/target)
- [x] Power bar tracks the limiting stat (fills in step with the all-4 gate)
- [x] Character portrait card on Hunter tab, updates on rank-up
- [x] Rank-up overlay with character portrait + reward summary (+50 Gold)
- [x] Month calendar with quest dot indicators per day
- [x] Day detail view (tap calendar cell), shows shield earned
- [x] Streak **earned by completing a quest** (not app-opens), with **Streak Shields** bridging missed days
- [x] Gold rewards per quest
- [x] **Gates removed** — redundant with the milestone shelf; replaced by the **Journal** tab. Shadow Army also gone.
- [x] **4-tab structure**: Hunter (be) · Quests (do) · Journal (reflect) · Feats (achieve)
- [x] Boss raids — stat/rank endgame goals that **pay gold once** when slain (`bossClaimMask`)
- [x] Milestones grid — small early wins, **gold** when earned (incl. shield + gate ties)
- [x] Completion = violet app-wide (quests, banner, gates CLEARED, ALL CLEAR, PERFECT DAY, READY)
- [x] Bonus quests as badge tiles (feed the shield system, no stat effect)
- [x] All-clear banner on Quests tab when all 5 done
- [x] **Local notifications** — repeating reminder + per-day streak-warning (cancelled when the day's done); `NotificationManager` in HunterStore, permission asked after onboarding
- [x] **Settings screen** (`SettingsView`, gear on Hunter tab) — notifications on/off + reminder/warning times (`@AppStorage`), edit rewards, edit name, about/version
- [x] **"Why did I miss" nudge** — when a quest goes 3 consecutive days un-done, a non-blocking gold banner on Quests offers to log why (preset reasons + optional note), one quest at a time, once per miss-episode (`currentNudge` / `MissReasonSheet`)
- [x] **Journal tab** (`JournalView`) — daily reflection + weekly coaching + insights, all on one roomy page
- [x] **Insights** — current/longest streak, total quests, gold; per-quest times-done + last-done; "why I missed" tally + recent log. Gives the `total*` counters a real purpose.
- [x] **Daily reflection** — two fields (what went well / what got in the way), stored in `Hunter.reflections`; feeds the coach with the miss-reasons
- [x] **Weekly AI coaching** — provider-agnostic `AICoach` + `GeminiCoach` (free tier; Claude-swappable), key in Keychain (Settings → AI Coach). Sends **only habit-relevant data** (per-habit weekly completions, all-time counts, streak, goals, miss-reasons, reflections — no stats/rank/power/gold). Coach is instructed to focus purely on *which habits aren't sticking, why, and what to try* — never number-chasing. (`HunterStore.buildWeeklyContext` / `requestWeeklyCoaching`)
- [x] **First-launch onboarding** — set hunter name + 5 real-life rewards
- [x] **Reward Vault** — gold sink: claim real-life rewards per rank (Locked / CLAIM / CLAIMED), editable
- [x] Rank-up overlay surfaces the unlocked real-life reward
- [x] Particle background
- [x] Launch screen
- [x] Hunter name edit
- [x] Haptics on quest complete and rank-up
- [x] **Juice animations** (SF Symbol effects + spring/glow): quest-icon bounce on CLAIM, all-clear burst, quest-clear popup, rank-up aura, streak flame pulse, reward-claim bounce, milestone-badge bounce on unlock
- [x] Dark theme throughout (`#07050F` base)

---

## What Needs Work 🔧

### High priority
- [ ] **D–S rank images** — user has the art; drop `rank_d`…`rank_s` into `Assets.xcassets` (code already references the names).

### Medium priority
- [ ] **Build verification** — all recent work was done on Windows; project hasn't been compiled. Needs a build in the iOS simulator to confirm.
- [ ] **Boss-slain celebration** — slaying a boss currently just adds gold silently; a popup/haptic moment would make it land.
- [ ] **Rank-down decision** — uncompleting quests can drop a rank (−50 gold) if a stat falls below the previous threshold (`checkRankDown`). Rare, but ranks usually feel permanent; consider removing it.

### Nice to have
- [ ] **Expand milestones** — currently an arbitrary 10; deferred. Could broaden coverage + add small gold rewards.
- [ ] **Micro-celebrations** — gate gold, boss gold, and reward claims are awarded silently; a toast + haptic would make them land.
- [ ] **Sound effects** — subtle audio on quest complete and rank-up
- [ ] **Widget** — iOS home screen widget showing today's quest progress ring
- [ ] **iCloud sync** — SwiftData supports CloudKit; add so data persists across reinstalls
- [ ] **S rank celebration** — reaching Eclipse General should have a special one-time cinematic moment beyond the standard rank-up overlay

---

## Known Issues 🐛

- `MagicCircleView.swift` emptied (content removed; safe to delete from the Xcode project)
- `HunterCharacterView.swift` trimmed — dead `HunterCharacterCard` removed; it still holds the **live** `HunterRankImage` + `RankUpCharacterView`, so keep the file
- Dead code removed from `HunterStore`: `lastClearedQuest`, `recentLogs(days:)`
- **Fresh install recommended after the rebalance** — added SwiftData fields (`Hunter.streakShields`, `bossClaimMask`, `gateClaimMask`, `maxStreak`, `hasOnboarded`, `rankRewardsData`, `questLastDoneData`, `questLastNudgedData`, `missLogData`, `reflectionsData`, `coachingSummary`, `coachingDate`; `DailyLog.shieldEarned`) all have defaults so migration shouldn't crash, but existing save data holds old inflated stat values (from the +8–12 era) that behave oddly against the new +1 thresholds, would skip onboarding, and would retroactively pay out all already-cleared gates' gold at once. Delete the app from the simulator before testing.
- **Reward title editing** persists on each keystroke (`RewardsView.titleBinding` → `setRewardTitle`); if focus feels janky on device, switch to save-on-submit.
- **Not yet compiled** — recent work done on Windows; needs an Xcode/simulator build to verify.
- **`AICoach.swift` is a NEW FILE** — must be added to the Xcode target (drag into the project, check the `SoloRise` target). Until then the build fails with `GeminiCoach`/`KeychainHelper`/`AICoachError` "not found in scope".
- **Gemini setup** — get a free key at Google AI Studio → Settings → AI Coach → paste → Save. If the request 404s, the model name has changed; update `GeminiCoach.model` (currently `gemini-2.0-flash`) to the current free model. The key lives in Keychain (fine for personal use; for public distribution route via a backend proxy so it isn't shippable in the binary).

---

*Last updated: June 2026 — quest rename/icons, +1 stat rebalance (~1yr E→S), streak shields,
stat-gated gates, all-clear banner, violet completion sweep, Feats rework (gold-paying stat/rank
bosses + small gold milestones), real-life Reward Vault + first-launch onboarding (gold sink), streak now earned by completing a quest, Shadow Army removed, gates pay gold on clear, dead-code cleanup, local notifications, juice animations, settings screen, "why did I miss" nudge + Insights page, daily reflection + weekly Gemini AI coaching, then restructured to 4 tabs (Gates removed → Journal tab); reflection reworked to went-well/got-in-the-way; coach refocused on habits-not-numbers.*
