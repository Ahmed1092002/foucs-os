# 12 · Risks & Edge Cases

## R1 · Timer drift ⏱️ HIGH
**Risk:** ticking a counter every second drifts over long sessions, especially if the JS engine throttles in background.
**Mitigation:** store `startedAt`, `endedAt`, and `pausedIntervals`; compute duration on demand from the system clock. **Never** trust the in-memory counter for persistence.
**Test:** unit tests with `FakeClock` for normal/pause/resume/stop; an integration test that simulates a 4-hour session with the timer service suspended.

## R2 · App killed mid-session 💀 HIGH
**Risk:** OS kills the app while a session is running; the user comes back hours later.
**Mitigation:** on every state transition (start/pause/resume/stop) persist immediately. On app launch, detect an "orphaned running session" (no `endedAt`, last update > 1h ago) and prompt: *Continue / End now / Discard?*

## R3 · Clock changes (user moves timezone, DST) 🕒 MEDIUM
**Risk:** if we use local time, a DST shift adds/removes an hour to a session.
**Mitigation:** store everything in UTC; convert to user timezone for display only. The backend also stores UTC.

## R4 · Offline sync conflicts 🔄 MEDIUM
**Risk:** user edits a subject on phone A offline, edits same subject on phone B; both come back online.
**Mitigation:** **last-writer-wins** on scalar fields (areas, subjects, plans). Sessions are **append-only** — they cannot conflict by definition. Reviews: LWW per `(user, date)`. Documented in API spec.

## R5 · Session started in past (clock skew) ⏪ LOW
**Risk:** user sets `startedAt` 3 hours ago when opening the app after an orphan.
**Mitigation:** cap to `min(now, startedAt)`; show "actual" anyway. Never allow `startedAt > now + 1min`.

## R6 · Daily plan across timezones 📅 MEDIUM
**Risk:** a plan for "today" is ambiguous if the user flies Cairo → Berlin.
**Mitigation:** use the user's stored IANA timezone for "today". Stats recompute when timezone changes (the user expects this).

## R7 · Large history queries 🐢 LOW (now) → MEDIUM (V2)
**Risk:** loading 5,000 sessions on app start.
**Mitigation:** paged cursors on the server, paged UI, virtualized lists (`flutter_sliver`).

## R8 · Auth token theft 🔐 MEDIUM
**Risk:** refresh token stolen from device.
**Mitigation:** Keychain (iOS) / Keystore (Android) for refresh; short-lived access; rotation on refresh; remote logout endpoint.

## R9 · Battery drain from background timer 🔋 LOW
**Risk:** the timer "service" wakes the device.
**Mitigation:** Flutter does NOT run a foreground service for MVP. The UI counter is for display only; the authoritative duration is computed from timestamps when needed. No wakeups.

## R10 · Loss of local DB 💾 MEDIUM
**Risk:** user reinstalls app or loses device; offline data not yet synced is gone.
**Mitigation:** encourage sync on every state change; show a "last synced" indicator; warn before destructive ops.

## R11 · Streak grief 📉 LOW (UX)
**Risk:** user breaks streak once and rage-quits.
**Mitigation:** streaks recover if the user studied ≥1 session the previous day AND today; never lose history. Empty states emphasize consistency, not the broken number.

## R12 · Planner overload 🧠 UX
**Risk:** user plans 14h/day.
**Mitigation:** deterministic warning tiers (green < 6h, yellow 6–10h, red > 10h). Never auto-modify. Suggest splitting days.

## R13 · AI temptation 🍩 PROCESS
**Risk:** scope creep into AI during MVP.
**Mitigation:** the AI module is forbidden in V1 by document [13](./13-future-ai-integration.md). PRs adding AI code are rejected.

## Edge cases list (acceptance checklist)
- [ ] Session longer than planned: no auto-stop.
- [ ] Session paused for 12h: still recoverable, can resume or end.
- [ ] Two sessions started at the same time: rejected.
- [ ] Session completed with `goalResult = null`: allowed (user skipped).
- [ ] Plan item past midnight (23:30–00:30): belongs to the start date.
- [ ] Subject deleted with sessions: cascade is intentional; sessions remain visible by id with a "deleted subject" placeholder.
- [ ] Review for a date with no sessions: allowed (e.g. rest day).
- [ ] Streak at year boundary: computed in local TZ; `longest` survives.