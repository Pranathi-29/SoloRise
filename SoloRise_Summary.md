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
│   ├── Hunter.swift          # Player model — stats, rank, gold, streak
│   ├── DailyLog.swift        # Per-day quest completion flags + buffs
│   └── QuestDefinition.swift # Quest metadata, rewards
├── ViewModels/
│   └── HunterStore.swift     # All game logic — quest completion, rank-up, streak
├── Views/
│   ├── Hunter/
│   │   ├── HunterView.swift         # Main Hunter tab
│   │   ├── HunterCharacterView.swift # Character card + rank images
│   │   ├── ActivityRingView.swift    # Quest ring + month calendar sheet
│   │   ├── DayDetailView.swift       # Per-day quest log (tapped from calendar)
│   │   ├── EditNameView.swift        # Hunter name editor
│   │   └── MagicCircleView.swift     # (legacy — can be deleted)
│   ├── Quests/
│   │   └── QuestsView.swift          # Daily quest list + passive buffs
│   ├── Gates/
│   │   └── GatesView.swift           # Gate registry + shadow army
│   ├── Feats/
│   │   └── FeatsView.swift           # Boss raids + milestones
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
| **Quests** | Daily quest checklist + passive buff toggles |
| **Gates** | Unlockable dungeons and shadow army (progress-gated) |
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
| Daily Training (workout) | STR | +10 |
| Nutrition (protein + fiber) | VIT | +8 |
| Skill Up (study/coding) | INT | +12 |
| Lore & Learning (reading) | WIS | +10 |
| Recovery Protocol (sleep/rest) | VIT | +8 |

### Rank Progression (stat-driven, XP removed)
| Rank | Title | Each stat must reach |
|------|-------|----------------------|
| E | Shadow Fragment | — (starting rank) |
| E → D | Shadow Scout | 20 each |
| D → C | Shadow Rogue | 40 each |
| C → B | Shadow Knight | 65 each |
| B → A | Shadow Commander | 95 each |
| A → S | Eclipse General | 130 each |

Power bar = `STR + INT + VIT + WIS` displayed in the Hunter status window.  
Rank up triggers automatically when **all 4 stats** meet the threshold.

### Passive Buffs (Quests tab)
| Buff | Effect |
|------|--------|
| Supplements taken | +5% VIT EXP bonus (legacy — currently no-op, see improvements) |
| Water goal reached | +8% VIT EXP bonus (legacy — currently no-op) |
| No junk food | +6% STR EXP bonus (legacy — currently no-op) |

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
- [x] Stat-driven rank-up system (XP removed)
- [x] Promotion requirements UI — per-stat checklist with ✓/target
- [x] Power bar replaces XP bar, colored by current rank
- [x] Character portrait card on Hunter tab, updates on rank-up
- [x] Rank-up overlay with character portrait + reward summary
- [x] Month calendar with quest dot indicators per day
- [x] Day detail view (tap calendar cell)
- [x] Streak tracking (resets on missed day)
- [x] Gold rewards per quest
- [x] Gates unlocked by stat milestones
- [x] Shadow army unlocked by cumulative counters
- [x] Boss raids with progress bars
- [x] Milestones grid
- [x] Passive buff toggles
- [x] Particle background
- [x] Launch screen
- [x] Hunter name edit
- [x] Haptics on quest complete and rank-up
- [x] Dark theme throughout (`#07050F` base)

---

## What Needs Work 🔧

### High priority
- [ ] **Passive buffs are broken** — buff toggles exist but the XP bonus system was removed with XP. Buffs need to be rewired to give stat bonuses instead (e.g. Supplements → +1 VIT on top of quest reward)
- [ ] **D–S rank images missing** — only `rank_e` is done. Need to generate and add `rank_d`, `rank_c`, `rank_b`, `rank_a`, `rank_s` portraits at matching dark-background style
- [ ] **No onboarding** — app drops straight into the Hunter tab with "Sung Jin-Woo" as default name. A first-launch name-entry screen would help

### Medium priority
- [ ] **Gates use hardcoded unlock conditions** — not connected to the new stat system. E.g. "Iron Keep" should unlock at STR 40, not `totalWorkouts >= 10`
- [ ] **Feats/milestones reference old XP** — some milestone checks (e.g. "Reached D-Rank") work fine, but boss raid thresholds are arbitrary counts, not stat-based
- [ ] **Promotion Requirements block adds scroll** — the Hunter tab is tight. Consider collapsing stats grid + promo requirements into a single compact section
- [ ] **Streak "0D" display** — streak shows "0D" instead of "0 DAYS" after the label shortening; either revert or make consistent

### Nice to have
- [ ] **Notifications** — daily reminder to complete quests, streak warning if not opened by evening
- [ ] **Quest history stats** — total workouts all-time, longest streak, etc. on the Feats tab
- [ ] **Sound effects** — subtle audio on quest complete and rank-up
- [ ] **Widget** — iOS home screen widget showing today's quest progress ring
- [ ] **iCloud sync** — SwiftData supports CloudKit; add so data persists across reinstalls
- [ ] **Buff rework** — make passive buffs meaningful again post-XP removal (stat bonuses, gold multipliers, or streak protection)
- [ ] **S rank celebration** — reaching Eclipse General should have a special one-time cinematic moment beyond the standard rank-up overlay

---

## Known Issues 🐛

- `MagicCircleView.swift` is no longer used — can be deleted
- `HunterCharacterView.swift` (the old SVG-drawn character) is replaced — delete if still present
- Removing `xp` from `Hunter.swift` requires a **fresh install** (delete app from simulator/device before running) — SwiftData will crash on schema mismatch with old data
- `QuestClearSheet` and `QuestsView` had `.xp` in `pillColor` switch — must be removed manually (no longer a valid `RewardType` case)

---

*Last updated: June 2026*
