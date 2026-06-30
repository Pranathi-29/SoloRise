# SoloRise — Product Review

*Assessment after the major feature build-out. Companion to `SoloRise_Summary.md`.*
*Last updated: June 2026*

---

## Overall Rating

**8 / 10 as a personal-use v1.**
*(~6.5 / 10 if judged as a public App Store product — the gap is sync, accessibility, and
distribution-readiness, not the design.)*

It began as a beautiful-but-hollow shell with a broken streak and a dead economy. It is now a
**coherent, differentiated, genuinely motivating product**. That is a large leap.

---

## What's Genuinely Strong

- **A real hook.** The real-life-reward commitment device + an AI coach that does *habit triage*
  (which habits aren't sticking, why, and what to try — not number-chasing) is a legitimately
  novel, useful combination. Most trackers shame you; this one helps.
- **Coherent loop — every screen earns its place.** Be (Hunter) · Do (Quests) · Reflect (Journal)
  · Achieve (Feats). Redundancy (Gates, Shadow Army) was *cut* rather than hoarded — rare discipline.
- **Sound behavioral design.** The streak measures real habits, shields reward consistency, and
  miss-reasons + daily reflections feed the coach. The pieces reinforce one another.
- **Strong, consistent visual identity** with juicy, on-theme feedback animations.

---

## What Can Be Improved

### Biggest levers (P0)
1. **iCloud sync** — the #1 risk. A year-long journey tied to real rewards with *no backup* is
   fragile; losing the phone at month 8 means losing everything. Needs an Apple Developer account
   + CloudKit capability.
2. **Full build verification** — a lot landed in untested batches, especially the **live Gemini
   call**. Confirm end-to-end before trusting it.
3. **Gemini key is client-side** — fine for personal use; for public release it must route through
   a backend proxy, plus a privacy disclosure (personal data is sent to Google).

### Real gaps (P1)
4. **Pacing is unvalidated.** The ~1-year curve + all-4-stats rank gate is theoretical; only living
   with it for a few weeks reveals whether it feels too slow or too fast. Tune after real use.
5. **Economy is now tight.** Removing both gate gold and reflection gold makes the top rewards
   (A/S) slow to afford. Watch it; reward costs may need lowering.
6. **Rank-down still exists** — unchecking a quest can drop a rank. Undecided, and potentially
   jarring; ranks usually feel permanent.
7. **No coaching cadence** — coaching is purely on-demand; a "your weekly review is ready"
   notification would actually drive people to read it.

### Polish (P2)
8. **Accessibility** — everything uses fixed `.system(size:)` fonts, so it won't respect Dynamic
   Type, and there's no VoiceOver consideration. The most overlooked gap for a real shipping app.
9. **Silent moments** — boss-slain and reward-claim could use a celebration beat; reaching S-rank
   deserves a one-time cinematic.
10. **Loose ends** — add the iOS home-screen **widget**, optional **sound effects**, and delete the
    now-dead `GatesView.swift` from the Xcode project.

### Beyond v1
11. **Single-player ceiling** — no social/accountability caps long-term retention and virality. The
    theme would support guilds/leaderboards well.

---

## Verdict

> *"It's become a thoughtfully-designed, genuinely original habit app with a standout AI-coaching
> hook — the kind of thing you'd actually run for a year. To make it trustworthy and shippable, the
> work shifts from 'design' to 'durability': sync it, verify it, and make it accessible."*

**Single highest-leverage next step: iCloud sync.** Everything else is refinement; that one
protects the entire premise.
