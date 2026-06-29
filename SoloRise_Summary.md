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
│   │   └── GatesView.swift           # Stat-gated gate registry
│   ├── Feats/
│   │   └── FeatsView.swift           # Stat/rank bosses (BossDefinition) + gold-paying, small milestones
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
| **Hunter** | Character profile, stats, power bar, promotion requirements, activity ring |
| **Quests** | Daily quest checklist + all-clear banner + bonus quests (streak shields) |
| **Gates** | Stat-gated dungeons and shadow army |
| **Feats** | Boss raids and milestone achievements |

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

### Gates (Gates tab)
Each gate is **stat-gated** and themed to a stat; two states only (Locked → CLEARED, no
"ENTERED"). Forest Dungeon VIT 25 · Iron Keep STR 40 · Scholar Vault INT 40 · Frost Citadel
WIS 65 · Inferno Rift STR 95 · Shadow Fortress WIS 130 · Monarchs Domain INT 130 · Ashborn
Throne Power 520. Clearing a gate pays a **one-time gold reward** (50 → 500 by tier, awarded
in `HunterStore.checkGates()` via `Hunter.gateClaimMask`). Beginners Gate is a free 0g starter.
The card shows the requirement + gold reward while locked, "CLEARED" once met.

### Feats (Feats tab)
Two tiers, defined in `FeatsView.swift`:
- **Bosses** = major stat/rank endgame goals (`BossDefinition`), **pay gold once** when first
  slain (tracked by `Hunter.bossClaimMask`, awarded in `HunterStore.checkBosses()`):
  Iron Troll → STR 190 (250g) · Procrastination Dragon → INT 190 (250g) · Chaos Monarch →
  Power 1200 (1000g).
- **Milestones** = small early wins, shown in **gold** when earned: first quest, first perfect
  day, 3/7/30-day streaks, D/C-Rank, 100 gold, cleared first gate (VIT 25), banked 3 shields.

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
- [x] Gates **stat-gated** (each themed to a stat), Locked / CLEARED, **pay one-time gold on clear**
- [x] Shadow Army **removed** (was purposeless / cosmetic)
- [x] Boss raids — stat/rank endgame goals that **pay gold once** when slain (`bossClaimMask`)
- [x] Milestones grid — small early wins, **gold** when earned (incl. shield + gate ties)
- [x] Completion = violet app-wide (quests, banner, gates CLEARED, ALL CLEAR, PERFECT DAY, READY)
- [x] Bonus quests as badge tiles (feed the shield system, no stat effect)
- [x] All-clear banner on Quests tab when all 5 done
- [x] **First-launch onboarding** — set hunter name + 5 real-life rewards
- [x] **Reward Vault** — gold sink: claim real-life rewards per rank (Locked / CLAIM / CLAIMED), editable
- [x] Rank-up overlay surfaces the unlocked real-life reward
- [x] Particle background
- [x] Launch screen
- [x] Hunter name edit
- [x] Haptics on quest complete and rank-up
- [x] Dark theme throughout (`#07050F` base)

---

## What Needs Work 🔧

### High priority
- [ ] **D–S rank images missing** — only `rank_e` is done. Need to generate and add `rank_d`, `rank_c`, `rank_b`, `rank_a`, `rank_s` portraits at matching dark-background style
- [ ] **Notifications** — daily reminder + evening streak-warning. Highest-ROI re-engagement gap (a habit app with no reminders).
- [ ] **"Why did I miss" feature (planned)** — a future feature to surface reasons for missed days and help with consistency. Pure accumulation was chosen partly to keep the per-day `DailyLog` history clean for this analysis.

### Medium priority
- [ ] **Build verification** — all recent work was done on Windows; project hasn't been compiled. Needs a build in the iOS simulator to confirm.
- [ ] **Boss-slain celebration** — slaying a boss currently just adds gold silently; a popup/haptic moment would make it land.
- [ ] **Legacy counters still exist** — `total*` counters on `Hunter` are now only used for the "first quest" milestone; could be removed once nothing else needs them.
- [ ] **Rank-down decision** — uncompleting quests can drop a rank (−50 gold) if a stat falls below the previous threshold (`checkRankDown`). Rare, but ranks usually feel permanent; consider removing it.

### Nice to have
- [ ] **Expand milestones** — currently an arbitrary 10; deferred. Could broaden coverage + add small gold rewards.
- [ ] **Micro-celebrations** — gate gold, boss gold, and reward claims are awarded silently; a toast + haptic would make them land.
- [ ] **Settings/Profile screen** — home for the notification toggle, about, edit-rewards shortcut.
- [ ] **Quest history stats** — all-time totals, longest streak, etc. on the Feats tab
- [ ] **Sound effects** — subtle audio on quest complete and rank-up
- [ ] **Widget** — iOS home screen widget showing today's quest progress ring
- [ ] **iCloud sync** — SwiftData supports CloudKit; add so data persists across reinstalls
- [ ] **S rank celebration** — reaching Eclipse General should have a special one-time cinematic moment beyond the standard rank-up overlay

---

## Known Issues 🐛

- `MagicCircleView.swift` emptied (content removed; safe to delete from the Xcode project)
- `HunterCharacterView.swift` trimmed — dead `HunterCharacterCard` removed; it still holds the **live** `HunterRankImage` + `RankUpCharacterView`, so keep the file
- Dead code removed from `HunterStore`: `lastClearedQuest`, `recentLogs(days:)`
- **Fresh install recommended after the rebalance** — added SwiftData fields (`Hunter.streakShields`, `bossClaimMask`, `gateClaimMask`, `hasOnboarded`, `rankRewardsData`; `DailyLog.shieldEarned`) all have defaults so migration shouldn't crash, but existing save data holds old inflated stat values (from the +8–12 era) that behave oddly against the new +1 thresholds, would skip onboarding, and would retroactively pay out all already-cleared gates' gold at once. Delete the app from the simulator before testing.
- **Reward title editing** persists on each keystroke (`RewardsView.titleBinding` → `setRewardTitle`); if focus feels janky on device, switch to save-on-submit.
- **Not yet compiled** — all recent work done on Windows; needs an Xcode/simulator build to verify.

---

*Last updated: June 2026 — quest rename/icons, +1 stat rebalance (~1yr E→S), streak shields,
stat-gated gates, all-clear banner, violet completion sweep, Feats rework (gold-paying stat/rank
bosses + small gold milestones), real-life Reward Vault + first-launch onboarding (gold sink), streak now earned by completing a quest, Shadow Army removed, gates pay gold on clear, dead-code cleanup.*
